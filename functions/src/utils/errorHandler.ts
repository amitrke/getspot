import {HttpsError, FunctionsErrorCode} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

/**
 * Standardized error handler for Cloud Functions.
 *
 * This utility provides consistent error handling across all callable functions:
 * - Logs errors with context
 * - Preserves HttpsError instances
 * - Wraps unknown errors in a user-friendly message
 * - Provides helper methods for common validation
 *
 * Usage:
 * ```typescript
 * import {handleError, validateAuth, validateArgs} from "./utils/errorHandler";
 *
 * export const myFunction = onCall(async (request) => {
 *   try {
 *     validateAuth(request);
 *     validateArgs(request.data, ["groupId", "action"]);
 *     // ... function logic
 *   } catch (error) {
 *     throw handleError(error, "myFunction");
 *   }
 * });
 * ```
 */

/**
 * Handle and normalize errors for Cloud Functions.
 *
 * @param {unknown} error - The caught error
 * @param {string} functionName - Name of the function for logging context
 * @return {HttpsError} HttpsError to be thrown to the client
 */
export function handleError(error: unknown, functionName: string): HttpsError {
  // Log the error with context
  logger.error(`Error in ${functionName}:`, error);

  // If it's already an HttpsError, preserve it
  if (error instanceof HttpsError) {
    return error;
  }

  // For other errors, wrap in a generic internal error
  const message = error instanceof Error ?
    error.message :
    "An unexpected error occurred.";

  return new HttpsError("internal", message);
}

/**
 * Create a standardized HttpsError with logging.
 *
 * @param {FunctionsErrorCode} code - The error code (e.g., "unauthenticated", "permission-denied")
 * @param {string} message - User-facing error message
 * @param {string} [functionName] - Optional function name for logging
 * @param {unknown} [details] - Optional additional details to log
 * @return {HttpsError} The created HttpsError
 */
export function createError(
  code: FunctionsErrorCode,
  message: string,
  functionName?: string,
  details?: unknown
): HttpsError {
  if (functionName) {
    logger.warn(`${functionName}: ${code} - ${message}`, details);
  }
  return new HttpsError(code, message);
}

/**
 * Validate that the request is authenticated.
 *
 * @param {Object} request - The callable request object
 * @throws {HttpsError} HttpsError if not authenticated
 */
export function validateAuth(request: {auth?: {uid: string}}): void {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to perform this action."
    );
  }
}

/**
 * Validate that required arguments are present.
 *
 * @param {Record<string, unknown>} data - The request data object
 * @param {string[]} requiredFields - Array of required field names
 * @throws {HttpsError} HttpsError if any required field is missing
 */
export function validateArgs(
  data: Record<string, unknown>,
  requiredFields: string[]
): void {
  const missing = requiredFields.filter(
    (field) => data[field] === undefined || data[field] === null
  );

  if (missing.length > 0) {
    throw new HttpsError(
      "invalid-argument",
      `Missing required parameters: ${missing.join(", ")}.`
    );
  }
}

/**
 * Validate that a document exists.
 *
 * @param {{exists: boolean}} doc - The Firestore document snapshot
 * @param {string} entityName - Name of the entity for error message (e.g., "group", "event")
 * @throws {HttpsError} HttpsError if document doesn't exist
 */
export function validateDocExists(
  doc: {exists: boolean},
  entityName: string
): void {
  if (!doc.exists) {
    throw new HttpsError(
      "not-found",
      `The ${entityName} was not found.`
    );
  }
}

/**
 * Validate that the user has admin permission for a group.
 *
 * @param {Object|undefined} groupData - The group document data
 * @param {string} uid - The user's UID
 * @param {string} [action] - Description of the action for error message
 * @throws {HttpsError} HttpsError if user is not the admin
 */
export function validateGroupAdmin(
  groupData: {admin?: string} | undefined,
  uid: string,
  action = "perform this action"
): void {
  if (!groupData || groupData.admin !== uid) {
    throw new HttpsError(
      "permission-denied",
      `You must be the group admin to ${action}.`
    );
  }
}

/**
 * Wrap an async function with standardized error handling.
 *
 * This is a higher-order function that wraps your function logic
 * and automatically handles errors.
 *
 * @param {string} functionName - Name of the function for error context
 * @param {Function} handler - The async handler function to wrap
 * @return {Function} Wrapped function with error handling
 *
 * Usage:
 * ```typescript
 * export const myFunction = onCall(
 *   withErrorHandler("myFunction", async (request) => {
 *     // Your function logic here
 *     return {success: true};
 *   })
 * );
 * ```
 */
export function withErrorHandler<T, R>(
  functionName: string,
  handler: (request: T) => Promise<R>
): (request: T) => Promise<R> {
  return async (request: T): Promise<R> => {
    try {
      return await handler(request);
    } catch (error) {
      throw handleError(error, functionName);
    }
  };
}
