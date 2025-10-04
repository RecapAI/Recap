Using print() statements for logging in production code is not recommended. These should use the logger instance that's already available in the class for consistent logging behavior.
Using Mirror for property access makes the code fragile and dependent on runtime reflection. Consider defining a protocol or using proper typed access to WhisperKit segment properties for better type safety and performance.
Using temporary security exceptions in production should be avoided. This entitlement bypasses sandbox restrictions and may not be acceptable for App Store distribution. Consider implementing proper audio unit hosting within the sandbox.
Avoid useless comments. A comment is useless when it does not add context about the code. Make explicit the why if you add a comment, not the how.
Check also the tests output, once you are done with the implementation of an increment.
Add missing files to membershipExceptions for the RecapTests in case of test failures related to missing types.
Function should have 5 parameters or less.
Line should be 120 characters or less.
Function parameters should be aligned vertically if they're in multiple lines in a declaration.
Files should have less than 400 lines.
Execute `swiftlint --strict` and fix the errors.
