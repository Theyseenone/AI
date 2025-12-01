# TODO: Modify Database Conversation Storage

## Tasks
- [x] Stack all conversations in one document
- [x] Store conversations as map in single document
- [x] Update loadChat to retrieve from conversations map
- [x] Update saveMessage to append to specific conversation in map
- [x] Add createNewConversation method for new chats

## Status
- All conversations stacked in single document 'conversations/all'
- Conversations stored as map with conversationId as key
- Each conversation has messages array
- Ready for testing
