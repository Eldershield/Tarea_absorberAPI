import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class Pokemon {
  final String name;
  final String imageUrl;
  final List<String> abilities;
  final List<String> type;
  final Map<String, dynamic> stats;

  Pokemon({
    required this.name,
    required this.imageUrl,
    required this.abilities,
    required this.type,
    required this.stats,
  });
}

class PokemonProvider with ChangeNotifier {
  List<Pokemon> _searchedPokemon = [];

  List<Pokemon> get searchedPokemon => _searchedPokemon;

  Future<void> searchPokemon(String query) async {
    final Dio dio = Dio();
    final response = await dio.get('https://pokeapi.co/api/v2/pokemon/$query');

    if (response.statusCode == 200) {
      final data = response.data;
      final abilities = (data['abilities'] as List<dynamic>)
          .map((e) => e['ability']['name'] as String)
          .toList();
      final type = (data['types'] as List<dynamic>)
          .map((type) => type['type']['name'] as String)
          .toList();
      final stats = Map<String, dynamic>.fromIterable(
        data['stats'],
        key: (stat) => stat['stat']['name'] as String,
        value: (stat) => stat['base_stat'],
      );
      final pokemon = Pokemon(
        name: data['name'],
        imageUrl: data['sprites']['front_default'],
        abilities: abilities,
        type: type,
        stats: stats,
      );

      _searchedPokemon = [pokemon];
      notifyListeners();
    } else {
      _searchedPokemon = [];
      notifyListeners();
      throw Exception('Failed to load Pokemon');
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PokemonProvider(),
      child: MaterialApp(
        title: 'Pokemon Search App',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final PokemonProvider pokemonProvider =
        Provider.of<PokemonProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscador Pokemon'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Nombre del Pokemon',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final query = _controller.text.trim().toLowerCase();
                    if (query.isNotEmpty) {
                      pokemonProvider.searchPokemon(query);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<PokemonProvider>(
                builder: (context, pokemonProvider, child) {
                  final searchedPokemon = pokemonProvider.searchedPokemon;
                  if (searchedPokemon.isEmpty) {
                    return const Center(
                      child: Text('No se encontro el pokemon'),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: searchedPokemon.length,
                      itemBuilder: (context, index) {
                        final pokemon = searchedPokemon[index];
                        return ListTile(
                          title: Text(pokemon.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Type: ${pokemon.type}'),
                              Text(
                                  'Abilities: ${pokemon.abilities.join(', ')}'),
                            ],
                          ),
                          leading: Image.network(pokemon.imageUrl),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        PokemonDetails(pokemon: pokemon)));
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PokemonDetails extends StatelessWidget {
  final Pokemon pokemon;

  PokemonDetails({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pokemon.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(pokemon.imageUrl),
            SizedBox(height: 20),
            Text('Types: ${pokemon.type.join(', ')}'),
            Text('Abilities: ${pokemon.abilities.join(', Hidden ability: ')}'),
            SizedBox(height: 10),
            Text('Stats:'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: pokemon.stats.entries.map((stat) {
                return Text('${stat.key}: ${stat.value}');
              }).toList(),
            )
            // Puedes agregar más detalles del Pokémon aquí
          ],
        ),
      ),
    );
  }
}
