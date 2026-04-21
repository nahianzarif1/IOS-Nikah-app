# Nikah iOS App

A SwiftUI matchmaking app with Firebase backend and Cloudinary media uploads.

## Overview

Nikah is an iOS application focused on profile-based matchmaking with:

- Authentication (register, login, logout, account delete)
- Multi-step profile creation and editing
- Discover feed with filters
- Like and match flow
- Real-time chat per match
- Shortlist and request management
- Report and block user actions

## Tech Stack

- SwiftUI
- MVVM architecture
- Firebase Authentication
- Cloud Firestore
- Cloudinary (image/audio upload)

## Project Structure

```text
IOS-Nikah-app/
  Nikah/
    CloudinaryService.swift
    ContentView.swift
    GoogleService-Info.plist
    NikahApp.swift

    Assets.xcassets/
      AccentColor.colorset/
      AppIcon.appiconset/

    Models/
      Filter.swift
      Match.swift
      Message.swift
      User.swift

    Services/
      AuthService.swift
      ChatService.swift
      FirebaseManager.swift
      MatchService.swift
      UserService.swift

    Utilities/
      Constants.swift
      Extensions.swift

    ViewModels/
      AuthViewModel.swift
      ChatViewModel.swift
      FeedViewModel.swift
      ProfileViewModel.swift

    Views/
      Auth/
        EmailVerificationView.swift
        LoginView.swift
        RegisterView.swift
      Chat/
        ChatDetailView.swift
        ChatListView.swift
      Feed/
        FilterView.swift
        HomeFeedView.swift
        ProfileCardView.swift
      Matches/
        MatchListView.swift
      Profile/
        CreateProfileView.swift
        EditProfileView.swift
        ProfileDetailView.swift
      Settings/
        SettingsView.swift

  Nikah.xcodeproj/

  firestore.rules
```

## Core Data Model (Firestore)

Top-level collections used by the app:

- users
- likes
- matches
- reports

Subcollection:

- matches/{matchId}/messages

## Local Setup

1. Clone/open the project in Xcode on macOS.
2. Add your Firebase iOS app config file:
   - `Nikah/GoogleService-Info.plist`
3. Ensure Firebase project has:
   - Authentication enabled (Email/Password)
   - Firestore database enabled
4. Deploy Firestore security rules from root `firestore.rules`.
5. Configure Cloudinary credentials in app constants/service configuration.
6. Build and run on simulator or device.

## Firebase Rules

A project-tailored Firestore rules file is included:

- `firestore.rules`

Deploy with Firebase CLI (from project root):

```bash
firebase deploy --only firestore:rules
```

## Main App Flow

1. User registers/logs in.
2. User completes profile onboarding.
3. User browses discover feed and sends likes.
4. Mutual like creates a match.
5. Matched users exchange messages in match chat.
6. Users can shortlist, block, and report profiles.

## Notes

- This repository currently contains the iOS app source and Firebase rules.
- Keep secrets and environment-specific keys out of source control.
