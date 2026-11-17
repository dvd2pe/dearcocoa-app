import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../notes/data/repositories/supabase_entries_pull.dart';
import '../../../notes/presentation/bloc/notes_fetch/notes_fetch_cubit.dart';

/// Gate for DearCocoa social features: requires a Supabase session.
/// When Supabase is not configured or the user is signed out, a friendly
/// sign-in page (with demo accounts) is shown instead of the child.
class DearCocoaAuthGate extends StatelessWidget {
  const DearCocoaAuthGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isSupabaseConfigured) {
      return const _UnconfiguredScreen();
    }
    final client = supabase!;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = client.auth.currentUser;
        final isLoading =
            !snapshot.hasData && session == null;
        if (isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (session == null) {
          return const DearCocoaSignInPage();
        }
        return child;
      },
    );
  }
}

class _UnconfiguredScreen extends StatelessWidget {
  const _UnconfiguredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DearCocoa')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 56, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'DearCocoa cloud features are not configured in this build.\n\n'
                'This APK was built without Supabase keys. Journaling, themes '
                'and all DiaryVault features keep working - the community, '
                'AI reflections, mood sync, group chat and events need '
                'SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sign-in page for the DearCocoa social layer (email/password) with
/// one-tap demo accounts. Journal stays private in DiaryVault either way.
class DearCocoaSignInPage extends StatefulWidget {
  const DearCocoaSignInPage({super.key});

  @override
  State<DearCocoaSignInPage> createState() => _DearCocoaSignInPageState();
}

class _DearCocoaSignInPageState extends State<DearCocoaSignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  int _selectedAccount = 0;

  /// Demo accounts prefilled in the form; the chips switch between them.
  static const _demoAccounts = [
    (name: 'Alex Rivera', email: 'alex@dearcocoa.demo'),
    (name: 'Maya Chen', email: 'maya@dearcocoa.demo'),
  ];
  static const _demoPassword = 'Cocoa2026!';

  @override
  void initState() {
    super.initState();
    // Prefill the first demo account so the client can sign in with one tap.
    _emailController.text = _demoAccounts[_selectedAccount].email;
    _passwordController.text = _demoPassword;
  }

  void _switchAccount(int index) {
    setState(() {
      _selectedAccount = index;
      _emailController.text = _demoAccounts[index].email;
      _passwordController.text = _demoPassword;
      _error = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn(String email, String password) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await supabase!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) {
        setState(() {
          _error = 'Sign in failed';
          _loading = false;
        });
        return;
      }
      // on success the auth gate rebuilds automatically
      // bring the user's cloud journal into the local journal, then refresh
      final added = await SupabaseEntriesPull.pullIntoLocalJournal();
      if (added > 0) {
        try {
          sl<NotesFetchCubit>().fetchNotes();
        } catch (_) {
          // journal screen not open yet: no refresh needed
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await supabase!.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! Check your inbox if confirmation is required.',
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('DearCocoa')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.spa_rounded,
                    size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  'Welcome to DearCocoa',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to join the community. Your journal stays '
                  'private on this device either way.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : () => _signIn(
                    _emailController.text.trim(),
                    _passwordController.text,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _loading ? null : _signUp,
                  child: const Text('Create account'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Demo accounts',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'The form is prefilled - switch or just tap Sign in.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _demoAccounts.length; i++)
                      ChoiceChip(
                        avatar: Icon(
                          i == 0
                              ? Icons.favorite_rounded
                              : Icons.spa_rounded,
                          size: 18,
                          color: i == _selectedAccount
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                        selected: i == _selectedAccount,
                        label: Text(_demoAccounts[i].name),
                        onSelected: _loading
                            ? null
                            : (_) => _switchAccount(i),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
