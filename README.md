# Nourish

Nourish is a Firebase-backed Flutter app for personalized nutrition, hydration, and workout planning on Android. It combines a user's body details, goal, diet preferences, ingredient exclusions, activity, equipment, and real weekly availability into practical daily targets and plans.

## Included

- Email/password authentication, password reset, and Google sign-in
- Four-step onboarding for height, weight, age, gender, goal, diet, exclusions, activity, exact workout weekdays, session length, and equipment
- Estimated calorie, protein, carbohydrate, fibre, hydration, BMR, and BMI values with wellness guardrails
- Vegetarian, non-vegetarian, and vegan recipe filtering
- 12 Firestore recipes with complete ingredients, instructions, allergen labels, and nutrition estimates
- Goal-aware recipe ranking for fat loss, muscle building, or weight maintenance
- Camera and gallery meal scanning with Firebase AI Logic, structured food recognition, confidence and assumption review, portion correction, and calorie/macro/fibre/sugar/sodium estimates
- Confirmed scanned meals added to the user's live Today totals; food photos are not stored by Nourish
- Two-to-six-day workout plans placed on the user's selected weekdays, with duration-aware exercise selection and bodyweight alternatives
- Persistent water quick-add and undo controls backed by per-user daily Firestore records
- Meal and workout logging in private per-user Firestore subcollections
- Editable profile and persistent Firebase workout plans
- Nourish raccoon branding across the app, Android splash screen, and adaptive launcher icon
- Safe-area-aware, responsive Material 3 interface for modern Android devices

## Firebase

- Project display name: `RohitProject`
- Project ID: `rohitproject-fit-ai`
- Firestore region: `asia-south1`
- Android package: `com.rohitproject.rohit_fit_ai`

The committed Firestore rules allow authenticated users to read the shared recipe catalog and restrict profile, meal, hydration, workout, and plan data to the matching Firebase user ID. Firebase App Check uses its debug provider in debug builds and Play Integrity in release builds.

## Run and test

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Build the Android APK with:

```sh
flutter build apk --release
```

Nutrition and body targets are general wellness estimates, not medical advice. Recipe nutrition varies with brands, oil, preparation, and serving size. Exercise should be adjusted or stopped if pain, dizziness, or unusual discomfort occurs.
