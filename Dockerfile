

import { type Request, type Response, type NextFunction } from 'express'
import * as utils from '../lib/utils'
import * as models from '../models/index'
import { UserModel } from '../models/user'
import { challenges } from '../data/datacache'
import * as challengeUtils from '../lib/challengeUtils'

class ErrorWithParent extends Error {
  parent: Error | undefined
}

// vuln-code-snippet start unionSqlInjectionChallenge dbSchemaChallenge
export function searchProducts () {
  return (req: Request, res: Response, next: NextFunction) => {
    let criteria: any = req.query.q === 'undefined' ? '' : req.query.q ?? ''
    criteria = (criteria.length <= 200) ? criteria : criteria.substring(0, 200)

    // ✅ SECURITY FIX: Parameterized query to prevent SQL injection
    models.sequelize.query(
      `SELECT * FROM Products
       WHERE (
         (name LIKE :criteria OR description LIKE :criteria)
         AND deletedAt IS NULL
       )
       ORDER BY name`,
      {
        replacements: { criteria: `%${criteria}%` }
      }
    )
      .then((result: any) => {
        const products = result[0]   // Sequelize returns [rows, metadata]
        const dataString = JSON.stringify(products)

        /* ---------------------------------------------
         * Challenge Logic (Kept Intact for Juice Shop)
         * --------------------------------------------- */

        // UNION SQL Injection Challenge (now cannot be solved due to fix)
        if (challengeUtils.notSolved(challenges.unionSqlInjectionChallenge)) {
          UserModel.findAll()
            .then(data => {
              const users = utils.queryResultToJson(data)
              let solved = true

              if (users.data?.length) {
                for (const user of users.data) {
                  solved =
                    solved &&
                    utils.containsOrEscaped(dataString, user.email) &&
                    utils.contains(dataString, user.password)

                  if (!solved) break
                }

                if (solved) {
                  challengeUtils.solve(challenges.unionSqlInjectionChallenge)
                }
              }
            })
            .catch((err: Error) => next(err))
        }

        // DB Schema Challenge
        if (challengeUtils.notSolved(challenges.dbSchemaChallenge)) {
          models.sequelize.query('SELECT sql FROM sqlite_master')
            .then((schemaResult: any) => {
              const schemaRows = schemaResult[0]
              const tableDefinitions = utils.queryResultToJson(schemaRows)
              let solved = true

              if (tableDefinitions.data?.length) {
                for (const row of tableDefinitions.data) {
                  if (row.sql) {
                    solved = solved && utils.containsOrEscaped(dataString, row.sql)
                    if (!solved) break
                  }
                }

                if (solved) {
                  challengeUtils.solve(challenges.dbSchemaChallenge)
                }
              }
            })
            .catch((err: Error) => next(err))
        }

        // Translate product fields
        for (const p of products) {
          p.name = req.__(p.name)
          p.description = req.__(p.description)
        }

        return res.json(utils.queryResultToJson(products))
      })
      .catch((error: ErrorWithParent) => {
        next(error.parent)
      })
  }
}
// vuln-code-snippet end unionSqlInjectionChallenge dbSchemaChallenge
