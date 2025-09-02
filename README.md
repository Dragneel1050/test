# Corbo App Spec

## Screen Inventory

| Screen Name         | Section      | Purpose |
|---------------------|-------------|---------|
| [Splash](#onboarding---splash)              | Onboarding  | Handles auto-login and contact preloading |
| [Onboarding](#onboarding---onboarding)          | Onboarding  | Phone number entry for authentication |
| [CodeView](#onboarding---codeview)            | Onboarding  | SMS verification step |
| [HomePermissionsWrapper](#onboarding---homepermissionswrapper) | Onboarding  | Requests location and contacts permissions |
| [GoogleSyncSettingsView](#onboarding---google-sync-settings) | Onboarding  | Enables Google email and calendar sync |
| [HomePermissionsWrapper](#onboarding---homepermissionswrapper) | Onboarding  | Imports device contacts |
| [NChatView](#chat---nchatview)           | Chat    | AI chat interface with context-aware conversations |
| [ChatHeaderView](#chat---chat-header)      | Chat    | Displays session title and provides session management options |
| [StoriesUsedView](#chat---storiesusedview)     | Chat    | Displays stories referenced in AI responses |
| [Settings](#settings---settings)            | Settings    | Provides access to sync settings and user preferences |
| [ProfileView](#settings---profileview)         | Settings    | User profile management and feed personalization |
| [DashboardView](#home---dashboardview)       | Home        | Main feed displaying AI recommendations and user activity |
| [Stories](#home---stories)             | Home        | Timeline-style view of AI-generated and imported stories |
| [ContactDetails](#home---contactdetails)      | Home        | View and manage contact-specific stories and interactions |
| [SideMenu](#side-menu---sidemenu)            | Side Menu   | Navigation menu with session history and quick actions |
| [Sessions](#side-menu---sessions)            | Side Menu   | Displays and manages past chat sessions |
| [EntityTray](#other---entitytray)          | Other       | Manages contact-entity associations for AI interactions |
| [RenameSessionTray](#other---renamesessiontray)   | Other       | Enables renaming of chat sessions |
| [ShareContentView](#other---sharecontentview)    | Other       | Handles content shared via iOS share sheet |

## Endpoint Inventory
| Screen | Method | Endpoint | Backend |
|--------|--------|----------|---------|
| [Splash](#onboarding---splash) | GET | /api/core/listContacts | Go |
| [Onboarding](#onboarding---onboarding) | POST | /api/core/requestPhoneCode | Go |
| [CodeView](#onboarding---codeview) | POST | /api/core/verifyPhoneCode | Go |
| [HomePermissionsWrapper](#onboarding---homepermissionswrapper) | POST | /api/core/syncContacts | Go |
| [GoogleSyncSettingsView](#onboarding---google-sync-settings) | POST | /v1/sync/email/settings | Python |
| [GoogleSyncSettingsView](#onboarding---google-sync-settings) | POST | /v1/sync/email/disable | Python |
| [GoogleSyncSettingsView](#onboarding---google-sync-settings) | GET | /v1/sync/email/status | Python |
| [GoogleSyncSettingsView](#onboarding---google-sync-settings) | POST | /v1/sync/calendar/disable | Calendar |
| [GoogleSyncSettingsView](#onboarding---google-sync-settings) | GET | /v1/sync/calendar/status | Calendar |
| [NChatView](#chat---nchatview) | POST | /v1/chat/ask?stream=True | Python |
| [NChatView](#chat---nchatview) | POST | /api/core/askWithStream | Go |
| [NChatView](#chat---nchatview) | POST | /api/core/createStory | Go |
| [NChatView](#chat---nchatview) | POST | /api/core/searchStories | Go |
| [NChatView](#chat---nchatview) | POST | /api/core/listSessions | Go |
| [NChatView](#chat---nchatview) | POST | /api/core/listSessionQuestions | Go |
| [NChatView](#chat---nchatview) | POST | /api/core/createSession | Go |
| [NChatView](#chat---nchatview) | POST | /api/core/renameSession | Go |
| [NChatView](#chat---nchatview) | POST | /api/core/deleteSession | Go |
| [StoriesUsedView](#chat---storiesusedview) | GET | /v1/question/{questionId}/details | Python |
| [ChatHeaderView](#chat---chat-header) | POST | /api/core/renameSession | Go |
| [ChatHeaderView](#chat---chat-header) | POST | /api/core/deleteSession | Go |
| [ProfileView](#settings---profileview) | POST | /api/core/updateUserData | Go |
| [ProfileView](#settings---profileview) | GET | /v1/feed?feedId=user&feedType=opportunity | Python |
| [ProfileView](#settings---profileview) | POST | /v1/feed/introduction | Python |
| [DashboardView](#home---dashboardview) | GET | /v1/feed?feedId=user | Python |
| [Stories](#home---stories) | POST | /api/core/prepareStoriesPage | Go |
| [ContactDetails](#home---contactdetails) | POST | /api/core/contactDetails | Go |
| [ContactDetails](#home---contactdetails) | POST | /api/core/updateContact | Go |
| [SideMenu](#side-menu---sidemenu) | POST | /api/core/listSessions | Go |
| [SideMenu](#side-menu---sidemenu) | POST | /api/core/createSession | Go |
| [SideMenu](#side-menu---sidemenu) | POST | /api/core/renameSession | Go |
| [SideMenu](#side-menu---sidemenu) | POST | /api/core/deleteSession | Go |
| [Sessions](#side-menu---sessions) | POST | /api/core/listSessions | Go |
| [Sessions](#side-menu---sessions) | POST | /api/core/listSessionQuestions | Go |
| [EntityTray](#other---entitytray) | POST | /api/core/searchContactByName | Go |
| [EntityTray](#other---entitytray) | POST | /api/core/createContact | Go |
| [EntityTray](#other---entitytray) | POST | /api/core/bindContactToEntity | Go |
| [RenameSessionTray](#other---renamesessiontray) | POST | /api/core/renameSession | Go |

## Screen Details

### Section: Onboarding

---

#### Onboarding - Splash

**Screen:** [Splash.swift](../Corbo/Views/Onboarding/Splash.swift)

**Purpose**  
Handles auto-login validation and preloading of contacts to ensure a seamless transition into the app.

**Features**  
- Checks for a valid session upon app launch  
- If authenticated, loads recent contacts  
- Navigates to Dashboard or Onboarding based on session status  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| GET    | /api/core/listContacts | Go |

**Implementation Details**  
- Uses an async authentication check on launch  
- Transitions to Dashboard on success, otherwise proceeds to Onboarding  

---

#### Onboarding - Onboarding

**Screen:** [Onboarding.swift](../Corbo/Views/Onboarding/Onboarding.swift)

**Purpose**  
Handles phone number entry for authentication and verification.

**Features**  
- User inputs phone number  
- Sends verification code via SMS  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| POST   | /api/core/requestPhoneCode | Go |

**Implementation Details**  
- Uses form validation to ensure valid phone number entry  
- Displays loading state while awaiting backend response  

---

#### Onboarding - CodeView

**Screen:** [CodeView.swift](../Corbo/Views/Onboarding/CodeView.swift)

**Purpose**  
Handles SMS verification for user authentication.

**Features**  
- User enters the received SMS code  
- Verifies code with backend before proceeding  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| POST   | /api/core/verifyPhoneCode | Go |

**Implementation Details**  
- Implements retry logic for resending verification codes  
- Uses animated UI elements to indicate validation states  

---

#### Onboarding - HomePermissionsWrapper

**Screen:** [HomePermissionsWrapper.swift](../Corbo/Views/Onboarding/HomePermissionsWrapper.swift)

**Purpose**  
Requests location and contacts permissions for app functionality.

**Features**  
- Requests user permissions for location tracking and contacts access  
- Provides explanations for permission requests  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| None   | None | None |

**Implementation Details**  
- Displays prompts for permission requests  
- Handles user responses and updates permissions accordingly  

---

#### Onboarding - Google Sync Settings

**Screen:** [GoogleSyncSettingsView.swift](../Corbo/Views/Onboarding/GoogleSyncSettingsView.swift)

**Purpose**  
Allows users to enable or disable Google email and calendar sync.

**Features**  
- Toggles for enabling/disabling Gmail and Calendar sync  
- Displays connection status  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| POST   | /v1/sync/email/settings | Python |  
| POST   | /v1/sync/email/disable | Python |  
| GET    | /v1/sync/email/status | Python |  
| POST   | /v1/sync/calendar/disable | Calendar |  
| GET    | /v1/sync/calendar/status | Calendar |  

**Implementation Details**  
- Uses async API calls to fetch and update sync preferences  
- UI state updates dynamically based on sync status  

### Section: Chat

---

#### Chat - NChatView

**Screen:** [NChatView.swift](../Corbo/Views/Chat/NChatView.swift)

**Purpose**  
Provides an AI-powered chat interface where users can interact with stored knowledge.

**Features**  
- AI chat with streaming responses  
- Context-aware discussions  
- Ability to create sessions, save stories, and refine topics  
- Supports long-press context menus for message actions  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| POST   | /v1/chat/ask?stream=True | Python |  
| POST   | /api/core/askWithStream | Go |  
| POST   | /api/core/createStory | Go |  
| POST   | /api/core/searchStories | Go |  
| POST   | /api/core/listSessions | Go |  
| POST   | /api/core/createSession | Go |  
| POST   | /api/core/renameSession | Go |  
| POST   | /api/core/deleteSession | Go |  

**Implementation Details**  
- Messages are streamed in real-time from backend  
- Caches messages for fast session restoration  
- Supports dynamic UI updates for better user experience  

---

#### Chat - Chat Header

**Screen:** [ChatHeaderView.swift](../Corbo/Views/Chat/ChatHeaderView.swift)

**Purpose**  
Displays the session title and provides options for session management.

**Features**  
- Displays chat session title  
- Long-press menu for renaming, deleting, or closing session  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| POST   | /api/core/renameSession | Go |  
| POST   | /api/core/deleteSession | Go |  

**Implementation Details**  
- Uses a modal for renaming sessions  
- Deletes sessions with a confirmation prompt  

---

#### Chat - StoriesUsedView

**Screen:** [StoriesUsedView.swift](../Corbo/Views/Chat/StoriesUsedView.swift)

**Purpose**  
Displays stories referenced in AI responses.

**Features**  
- Shows stories that have been referenced during chat sessions  
- Allows users to tap on stories to view details  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| None   | None | None |

**Implementation Details**  
- Integrates with chat history to fetch relevant stories  
- Displays stories in a user-friendly format  

### Section: Settings

---

#### Settings - Settings

**Screen:** [Settings.swift](../Corbo/Views/Settings/Settings.swift)

**Purpose**  
Provides access to sync settings and user preferences.

**Features**  
- Options to manage sync settings  
- Access to user profile management  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| None   | None | None |

**Implementation Details**  
- Uses a structured layout for easy navigation  
- Updates preferences in real-time  

---

#### Settings - ProfileView

**Screen:** [ProfileView.swift](../Corbo/Views/Settings/ProfileView.swift)

**Purpose**  
User profile management and feed personalization.

**Features**  
- Allows users to update their profile information  
- Provides options for feed customization  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| POST   | /api/core/updateProfile | Go |  

**Implementation Details**  
- Utilizes forms for profile updates  
- Fetches user data on load  

### Section: Home

---

#### Home - DashboardView

**Screen:** [DashboardView.swift](../Corbo/Views/Home/DashboardView.swift)

**Purpose**  
Main feed displaying AI recommendations and user activity.

**Features**  
- Displays personalized content based on user activity  
- Integrates with chat history for recommendations  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| GET    | /api/core/dashboard | Go |  

**Implementation Details**  
- Uses a grid layout for displaying content  
- Updates content dynamically based on user interactions  

---

#### Home - Stories

**Screen:** [Stories.swift](../Corbo/Views/Home/Stories/Stories.swift)

**Purpose**  
Displays a timeline of past interactions, emails, calendar events, and AI-generated stories.

**Features**  
- Shows stories categorized by type (Email, AI, Calendar, etc.)  
- Users can tap a story to view its full content  
- Supports filtering and searching stories  
- Allows creation of new stories  
- Integrates with chat history  
- Context menu for saving or sharing stories  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| POST   | /api/core/prepareStoriesPage | Go |  

**Implementation Details**  
- Uses `LazyVStack` for efficient scrolling  
- Fetches stories on `.onAppear`  
- API response is processed into `StoryModel` objects  

---

#### Home - ContactDetails

**Screen:** [ContactDetails.swift](../Corbo/Views/Home/ContactDetails.swift)

**Purpose**  
Displays and manages user contacts, allowing for viewing and editing.

**Features**  
- Displays contact info  
- Allows updating details  
- Shows linked stories  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| POST   | /api/core/contactDetails | Go |  
| POST   | /api/core/updateContact | Go |  

**Implementation Details**  
- Uses a structured form layout for editing contacts  
- Fetches stories linked to the contact  

### Section: Side Menu

---

#### Side Menu - SideMenu

**Screen:** [SideMenu.swift](../Corbo/Views/SideMenu/SideMenu.swift)

**Purpose**  
Provides navigation and session history management.

**Features**  
- Displays a list of past chat sessions  
- Allows users to create new sessions  
- Context menu for renaming or deleting sessions  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| POST   | /api/core/listSessions | Go |  
| POST   | /api/core/createSession | Go |  
| POST   | /api/core/renameSession | Go |  
| POST   | /api/core/deleteSession | Go |  

**Implementation Details**  
- Uses `LazyVStack` for optimized scrolling  
- Handles user gestures for quick actions  

### Section: Other Screens

---

#### Other - EntityTray

**Screen:** [EntityTray.swift](../Corbo/Views/Other/EntityTray.swift)

**Purpose**  
Manages contact-entity associations for AI interactions.

**Features**  
- Displays entities associated with contacts  
- Allows users to manage these associations  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| None   | None | None |

**Implementation Details**  
- Integrates with contact management system  
- Supports adding and removing associations  

---

#### Other - RenameSessionTray

**Screen:** [RenameSessionTray.swift](../Corbo/Views/Other/RenameSessionTray.swift)

**Purpose**  
Enables renaming of chat sessions.

**Features**  
- Input field for new session name  
- Confirmation prompt for renaming  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| None   | None | None |

**Implementation Details**  
- Uses modal presentation for renaming sessions  
- Validates input before renaming  

---

#### Other - ShareContentView

**Screen:** [ShareContentView.swift](../Corbo/Views/Other/ShareContentView.swift)

**Purpose**  
Handles content shared via iOS share sheet.

**Features**  
- Displays shared content options  
- Allows users to share content through various channels  

**API Calls**  
| Method | Path | Service |
|--------|------|---------|
| None   | None | None |

**Implementation Details**  
- Integrates with iOS share functionality  
- Supports multiple content types for sharing  
