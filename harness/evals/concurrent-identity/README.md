# concurrent-identity

Checks that simultaneous creators never receive the same work-order or bug number.

Scanning the folders to find the highest number and creating afterwards is a race: every
creator reads the same maximum before any of them has written anything, and all of them
believe they own the next number. The result is several records carrying one identity, which
makes each of them unaddressable by every later command.
