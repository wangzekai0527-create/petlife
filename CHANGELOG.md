# Changelog

## 2026-04-09

- Fixed sign-out session cleanup so one user's local pets, posts, videos, memories, and chats do not leak into another session.
- Replaced fuzzy chat thread reuse with stable pet-based thread identity.
- Added stable `relatedPetID` linkage for posts and chat threads to improve routing correctness.
- Fixed the social feed context menu `"进入详情"` action so it now opens the existing post detail screen.
- Kept the change set limited to correctness and navigation fixes without expanding product scope.
