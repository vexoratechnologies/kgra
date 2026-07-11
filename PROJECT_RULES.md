# KGRA Mobile Application - Flutter Development Rules

## Project Goal

Build a **production-ready**, scalable Flutter application using **Firebase** as the backend and **Provider** for state management.

The application should follow clean coding principles, maintainable architecture, reusable components, and deliver a premium user experience.

---

# Tech Stack

Framework

* Flutter (Latest Stable)

State Management

* Provider (ChangeNotifier)

Backend

* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* Firebase Cloud Messaging

Local Storage

* SharedPreferences
* Hive (if needed for caching)

Dependency Injection

* get_it

Navigation

* go_router (preferred) or centralized NavigationService

Image Loading

* cached_network_image

Video

* video_player
* chewie

PDF

* syncfusion_flutter_pdfviewer

Payments

* Razorpay

Logging

* logger

Utilities

* intl
* flutter_svg
* lottie

---

# Architecture

Use Feature First Architecture.

Never place the entire application inside one large folder.

Project Structure

```text
lib/

core/

    constants/
    helpers/
    services/
    routes/
    theme/
    widgets/
    utils/
    extensions/
    animations/

features/

    auth/
    home/
    profile/
    video/
    notification/
    payment/
    beneficiary/
    zonal/
    state_committee/
    settings/

main.dart
app.dart
injection.dart
```

---

# Every Feature Must Contain

```text
feature/

presentation/

    screens/
    widgets/
    providers/

data/

    firebase/
    repositories/
    models/
```

Never mix UI and Firebase logic.

---

# Architecture Flow

Always follow

```text
Screen

↓

Provider

↓

Repository

↓

Firebase Service

↓

Firestore/Auth/Storage

↓

Model

↓

Provider

↓

UI
```

Never skip layers.

---

# Provider Rules

Use ChangeNotifier.

Every feature must have its own Provider.

Examples

```text
AuthProvider

HomeProvider

VideoProvider

ProfileProvider

NotificationProvider

PaymentProvider

BeneficiaryProvider

ZoneProvider

StateCommitteeProvider
```

Never create one huge provider.

Providers should

* Handle loading state
* Handle UI state
* Call Repository
* Notify listeners

Providers must NOT

* Access Firestore directly
* Access Firebase Storage directly
* Access FirebaseAuth directly

---

# Repository Rules

Every feature must have Repository.

Example

```text
AuthRepository

VideoRepository

ProfileRepository

NotificationRepository

PaymentRepository
```

Repository responsibilities

* Firestore CRUD
* Firebase Storage
* Firebase Auth
* Firebase Messaging

No UI logic.

---

# Firebase Service Rules

Create reusable services.

```text
FirestoreService

StorageService

NotificationService

AuthenticationService
```

All Firebase code belongs here.

Never duplicate Firebase code.

---

# Firestore Rules

Never write

```dart
FirebaseFirestore.instance
```

inside UI.

Use Repository.

All Collection names must be constants.

Wrong

```dart
.collection("USERS")
```

Correct

```dart
FirestoreCollections.users
```

Never hardcode document field names.

Create

```text
FirestoreFields
```

---

# Model Rules

Every Firestore document must have a Model.

Every Model must contain

```dart
fromJson()

toJson()

copyWith()

toString()

==

hashCode
```

No raw Maps inside UI.

---

# UI Rules

Widgets only display data.

Business logic is not allowed.

Firestore logic is not allowed.

Storage logic is not allowed.

Authentication logic is not allowed.

Long calculations are not allowed.

---

# Widget Rules

Create reusable widgets.

Examples

```text
AppButton

AppTextField

AppSearchField

AppLoading

ErrorWidget

EmptyWidget

ProfileTile

VideoCard

SchemeCard

CommitteeCard

NotificationTile

PrimaryButton

SecondaryButton

CustomDialog
```

Never duplicate UI.

---

# Theme Rules

Never hardcode

Colors

TextStyle

BorderRadius

Padding

FontSize

Create

```text
AppColors

AppTextStyle

AppDimensions

AppTheme

AppRadius

AppSpacing
```

Entire application should use Theme.

---

# Navigation Rules

Use centralized navigation.

Never scatter routes across files.

Create

```text
AppRoutes
```

Example

```text
Splash

Login

OTP

Home

Profile

Videos

VideoDetails

Notification

Settings

Payment

Beneficiary
```

Never hardcode route strings.

---

# Page Transition Rules

Every navigation must have smooth animation.

Default

Fade + Slide

Duration

300 milliseconds

Curve

easeInOutCubic

Main Navigation

Slide Right → Left

Back Navigation

Slide Left → Right

Dialogs

Scale + Fade

Bottom Sheets

Slide From Bottom

Image Preview

Hero Animation

Profile Image

Gallery

Video Thumbnail

PDF Viewer

Slide Right

Authentication Flow

Splash

↓

Fade

↓

Login

↓

Slide

↓

OTP

↓

Scale

↓

Success

↓

Fade

↓

Home

---

# Animation Rules

Application should feel premium.

Use

AnimatedContainer

AnimatedSwitcher

Hero

AnimatedOpacity

TweenAnimationBuilder

ScaleTransition

FadeTransition

SlideTransition

Never overuse animations.

Duration

250–350ms

Micro Animation

150ms

---

# Loading Rules

Never show blank pages.

Use

Skeleton

Shimmer

Loading Indicator

Progress Indicator

Buttons must display loading state.

---

# Button Rules

Buttons should

Ripple

Scale on Tap

Disable while loading

Prevent multiple taps

---

# List Rules

Animate list appearance.

Use Fade + Slide.

Do not instantly show content.

---

# Empty State

Every empty page must have

Illustration

Message

Retry Button

Never display blank white screen.

---

# Error Handling

Never

```dart
catch(e){}
```

Always

Log error

Show user-friendly message

Provider should expose

```dart
loading

error

success
```

---

# Logging Rules

Never use

print()

Use

logger

or

debugPrint()

Release mode should not print logs.

---

# Asset Rules

```text
assets/

images/

icons/

animations/

lottie/

fonts/

pdf/
```

Keep assets organized.

---

# Constants

Create

```text
AppStrings

AppAssets

FirestoreCollections

FirestoreFields

AppConstants
```

Never hardcode strings.

---

# Utilities

Create

```text
DateFormatter

Validators

Extensions

SnackBarHelper

DialogHelper

PermissionHelper

ImagePickerHelper

ConnectivityHelper
```

---

# Folder Naming

snake_case

Example

```text
profile_screen.dart

video_repository.dart

notification_provider.dart

payment_model.dart
```

Classes

PascalCase

Variables

camelCase

Private

_startLoading

---

# Code Rules

One class

One responsibility

One function

One responsibility

Avoid functions over 50 lines.

Extract reusable methods.

Avoid duplicated code.

Prefer composition over inheritance.

---

# Performance Rules

Use const widgets.

Dispose controllers.

Dispose animation controllers.

Dispose TextEditingControllers.

Avoid rebuilding whole screens.

Use Consumer only where required.

Use Selector when appropriate.

Cache Firestore results where possible.

Paginate large Firestore collections.

---

# Firebase Rules

Always validate user before Firestore access.

Use Firestore Security Rules.

Never trust client validation.

Optimize queries.

Avoid downloading unnecessary data.

Use indexes for compound queries.

Use batch writes where appropriate.

Use transactions for critical updates.

---

# Notification Rules

Centralize notification handling.

Use NotificationService.

Handle

Foreground

Background

Terminated

Notification click

Navigation from notification

---

# Storage Rules

Compress images before upload.

Delete unused files.

Use proper folder naming.

Example

```text
profile/

videos/

documents/

schemes/
```

---

# Git Rules

One feature per branch.

Commit frequently.

Examples

```text
feat: authentication completed

feat: profile screen

fix: notification issue

refactor: move firestore logic to repository

style: improve dashboard ui
```

Never commit generated files unnecessarily.

---

# Documentation

Document

Complex Providers

Repositories

Firebase Services

Setup Process

README

---

# UI Design Rules

Follow Material Design 3.

Maintain 8dp spacing system.

Consistent radius.

Consistent typography.

Responsive on

Phone

Tablet

Landscape

Support accessibility.

Use meaningful icons.

Follow modern UI principles.

---

# User Experience Rules

The application should feel

Fast

Premium

Smooth

Modern

Responsive

Elegant

Animations should never feel slow.

Navigation should never feel abrupt.

Every action should provide user feedback.

Avoid unnecessary loading.

Optimize for smooth scrolling.

---

# AI Coding Rules

When generating code:

* Never generate duplicate widgets.
* Always reuse existing components.
* Prefer composition over duplication.
* Follow project architecture strictly.
* Keep code modular and testable.
* Never place Firebase logic in UI.
* Never hardcode colors, strings, collection names, or dimensions.
* Generate null-safe Dart code.
* Prefer readable, maintainable code over clever code.
* Add documentation comments for public classes and complex methods.
* Keep imports clean and remove unused code.

---

# Final Development Principle

Every piece of code must be written as if the application will be maintained for the next 5+ years by a team of developers.

Prioritize:

1. Readability
2. Reusability
3. Maintainability
4. Performance
5. Scalability
6. Consistency
7. Premium User Experience

The final application should be production-ready, scalable, clean, responsive, and visually polished.
