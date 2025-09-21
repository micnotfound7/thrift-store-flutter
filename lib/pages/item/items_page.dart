// lib/pages/items_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/supabase_service.dart';
import '../../models/item.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});
  @override
  ItemsPageState createState() => ItemsPageState();
}

class ItemsPageState extends State<ItemsPage> {
  late Future<List<Item>> _fetchFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    final svc = Provider.of<SupabaseService>(context, listen: false);
    _fetchFuture = svc.fetchItems().then((_) => svc.items);
  }

  Future<void> _refresh() async {
    _loadItems();
    await _fetchFuture;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<SupabaseService>(context, listen: false);
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003366), Color(0xFF144D73)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '🏪 C Thrift Store',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Color(0xFFC7E6DE)),
                      onPressed: () async {
                        await svc.signOut();
                        if (mounted) {
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/signin', (_) => false);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF5AB69F),
                  onRefresh: _refresh,
                  child: FutureBuilder<List<Item>>(
                    future: _fetchFuture,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFC7E6DE)),
                        );
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            'Oops! ${snap.error}',
                            style:
                            GoogleFonts.montserrat(color: Colors.redAccent),
                          ),
                        );
                      }
                      final items = snap.data!;
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            'No treasures yet 🧐',
                            style: GoogleFonts.lato(
                              color: const Color(0xFFC7E6DE).withOpacity(0.8),
                              fontSize: 18,
                            ),
                          ),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          final isOwner = item.uploaderEmail == currentEmail;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Hero(
                                    tag: 'item-image-${item.id}',
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.network(
                                            item.imageUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        if (isOwner)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF003366)
                                                    .withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.delete,
                                                    size: 20),
                                                color: const Color(0xFFE4F0F3),
                                                onPressed: () async {
                                                  await svc.deleteItem(item.id);
                                                  await _refresh();
                                                },
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF003366),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '₱ ${item.price.toStringAsFixed(2)}',
                                        style: GoogleFonts.lato(
                                          fontSize: 14,
                                          color: const Color(0xFF5AB69F),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'By ${item.uploadedBy}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.lato(
                                          fontSize: 12,
                                          color: const Color(0xFF144D73),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            const Color(0xFF144D73),
                                            foregroundColor:
                                            const Color(0xFFE4F0F3),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/detail',
                                              arguments: item.id,
                                            );
                                          },
                                          child: Text(
                                            'Details',
                                            style: GoogleFonts.lato(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF5AB69F),
                  foregroundColor: const Color(0xFF003366),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add New',
                    style:
                    GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/add');
                    await _refresh();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}