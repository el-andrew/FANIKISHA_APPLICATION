import 'package:fanikisha/core/router/app_router.dart';
import 'package:fanikisha/features/auth/application/auth_controller.dart';
import 'package:fanikisha/features/auth/data/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = User(id: 'u', email: 'a@b.co', fullName: 'Asha M');

  test('holds every route on the splash screen while the session loads', () {
    expect(redirectFor(const AuthLoading(), '/goals'), '/splash');
    expect(redirectFor(const AuthLoading(), '/splash'), isNull);
    expect(redirectFor(AuthRestoreFailed(Exception()), '/'), '/splash');
  });

  test('sends signed-out users to the welcome screen', () {
    expect(redirectFor(const SignedOut(), '/'), '/welcome');
    expect(redirectFor(const SignedOut(), '/goals/abc'), '/welcome');
    expect(redirectFor(const SignedOut(), '/login'), isNull);
    expect(redirectFor(const SignedOut(), '/register'), isNull);
  });

  test('keeps signed-in users out of the sign-in screens', () {
    expect(redirectFor(const SignedIn(user), '/login'), '/');
    expect(redirectFor(const SignedIn(user), '/splash'), '/');
    expect(redirectFor(const SignedIn(user), '/goals/abc'), isNull);
  });
}
