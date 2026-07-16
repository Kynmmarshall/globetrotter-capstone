import 'package:flutter/material.dart';

import 'src/models.dart';
import 'src/session_controller.dart';

class TripIoApp extends StatefulWidget {
  const TripIoApp({super.key});

  @override
  State<TripIoApp> createState() => _TripIoAppState();
}

class _TripIoAppState extends State<TripIoApp> {
  final SessionController _session = SessionController();

  @override
  void initState() {
    super.initState();
    _session.initialize();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return MaterialApp(
          title: 'GlobeTrotter',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF0A7E8C),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (!_session.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_session.isAuthenticated) {
      return AuthScreen(session: _session);
    }
    return DashboardScreen(session: _session);
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loginMode = true;

  @override
  void initState() {
    super.initState();
    _baseUrlController.text = widget.session.baseUrl;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await widget.session.updateBaseUrl(_baseUrlController.text);
    if (_loginMode) {
      await widget.session.login(_usernameController.text.trim(), _passwordController.text);
    } else {
      await widget.session.register(_usernameController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _loginMode ? 'Welcome Back' : 'Create Account',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _baseUrlController,
                        decoration: const InputDecoration(labelText: 'Backend Base URL'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Base URL is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Username'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Username is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Password is required' : null,
                      ),
                      if (widget.session.error != null) ...[
                        const SizedBox(height: 12),
                        Text(widget.session.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: widget.session.isLoading ? null : _submit,
                        child: widget.session.isLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_loginMode ? 'Login' : 'Register'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: widget.session.isLoading
                            ? null
                            : () {
                                setState(() {
                                  _loginMode = !_loginMode;
                                });
                              },
                        child: Text(_loginMode ? 'No account? Register' : 'Already have an account? Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  static const _labels = <String>['Destinations', 'Recommendations', 'Itineraries', 'Profile'];
  static const _icons = <IconData>[Icons.public, Icons.star, Icons.map, Icons.person];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DestinationsPage(session: widget.session),
      RecommendationsPage(session: widget.session),
      ItinerariesPage(session: widget.session),
      ProfilePage(session: widget.session),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final medium = constraints.maxWidth >= 700;

        if (wide || medium) {
          return Scaffold(
            appBar: AppBar(title: Text(_labels[_index])),
            body: Row(
              children: [
                NavigationRail(
                  extended: wide,
                  selectedIndex: _index,
                  onDestinationSelected: (idx) => setState(() => _index = idx),
                  destinations: List.generate(_labels.length, (i) {
                    return NavigationRailDestination(
                      icon: Icon(_icons[i]),
                      label: Text(_labels[i]),
                    );
                  }),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages[_index]),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(_labels[_index])),
          body: pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (idx) => setState(() => _index = idx),
            destinations: List.generate(_labels.length, (i) {
              return NavigationDestination(
                icon: Icon(_icons[i]),
                label: _labels[i],
              );
            }),
          ),
        );
      },
    );
  }
}

class DestinationsPage extends StatefulWidget {
  const DestinationsPage({super.key, required this.session});

  final SessionController session;

  @override
  State<DestinationsPage> createState() => _DestinationsPageState();
}

class _DestinationsPageState extends State<DestinationsPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Destination>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.session.destinations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _future = widget.session.destinations(query: _searchController.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(labelText: 'Search destinations by name or tag'),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _search, child: const Text('Search')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Destination>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final items = snapshot.data ?? <Destination>[];
                if (items.isEmpty) {
                  return const Center(child: Text('No destinations found.'));
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1000 ? 3 : (width >= 650 ? 2 : 1);
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final d = items[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.name, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(d.country),
                                const Spacer(),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: d.tags.map((t) => Chip(label: Text(t))).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key, required this.session});

  final SessionController session;

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  late Future<List<Destination>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.session.recommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<Destination>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? <Destination>[];
          if (items.isEmpty) {
            return const Center(child: Text('No recommendations yet.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.place),
                title: Text(item.name),
                subtitle: Text('${item.country}  •  ${item.tags.join(', ')}'),
              );
            },
          );
        },
      ),
    );
  }
}

class ItinerariesPage extends StatefulWidget {
  const ItinerariesPage({super.key, required this.session});

  final SessionController session;

  @override
  State<ItinerariesPage> createState() => _ItinerariesPageState();
}

class _ItinerariesPageState extends State<ItinerariesPage> {
  final _titleController = TextEditingController();
  final _destinationsController = TextEditingController();
  late Future<List<Itinerary>> _future;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _future = widget.session.itineraries();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationsController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.session.itineraries();
    });
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    final destinations = _destinationsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (title.isEmpty || destinations.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter title and at least one destination id.')),
      );
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      await widget.session.createItinerary(title, destinations);
      _titleController.clear();
      _destinationsController.clear();
      await _refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Itinerary created.')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Itinerary title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _destinationsController,
                    decoration: const InputDecoration(
                      labelText: 'Destination IDs (comma-separated)',
                      hintText: 'd1,d2',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _creating ? null : _create,
                      child: _creating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Create Itinerary'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<Itinerary>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final items = snapshot.data ?? <Itinerary>[];
                if (items.isEmpty) {
                  return const Center(child: Text('No itineraries yet.'));
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        title: Text(item.title),
                        subtitle: Text('Destinations: ${item.destinations.join(', ')}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in as: ${session.username ?? 'unknown'}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text('API Base URL: ${session.baseUrl}'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => session.logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
