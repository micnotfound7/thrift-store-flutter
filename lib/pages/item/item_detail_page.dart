// lib/pages/item_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/supabase_service.dart';
import '../../models/item.dart';
import '../../widgets/info_chip.dart';
import 'full_screen_image_page.dart';

class ItemDetailPage extends StatelessWidget {
  final int itemId;
  const ItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<SupabaseService>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE4F0F3), Color(0xFFC7E6DE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Item?>(
            future: svc.fetchItemDetail(itemId),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF144D73)),
                );
              }
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snap.error}',
                    style: GoogleFonts.montserrat(color: Colors.redAccent),
                  ),
                );
              }
              final item = snap.data;
              if (item == null) {
                return Center(
                  child: Text(
                    'Item not found 🤷',
                    style: GoogleFonts.montserrat(color: const Color(0xFF144D73)),
                  ),
                );
              }

              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Back + title
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child:
                            const Icon(Icons.arrow_back_ios, color: Color(
                                0xFF151303)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Details',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF003366),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tappable image with Hero
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FullScreenImagePage(itemId: item.id, imageUrl: item.imageUrl),
                          ),
                        ),
                        child: Hero(
                          tag: 'item-image-${item.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              item.imageUrl,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),


                      Text(
                        item.title,
                        style: GoogleFonts.montserrat(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003366),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱ ${item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5AB69F),
                        ),
                      ),
                      const SizedBox(height: 24),


                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF144D73),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF003366),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: const Color(0xFF144D73),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info chips
                      SizedBox(
                        height: 40,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              InfoChip(icon: Icons.person, text: item.uploadedBy),
                              const SizedBox(width: 8),
                              InfoChip(icon: Icons.contact_mail, text: item.contactInfo),
                              const SizedBox(width: 8),
                              InfoChip(
                                icon: Icons.calendar_today,
                                text: '${item.createdAt.month}/${item.createdAt.day}/${item.createdAt.year}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),


                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5AB69F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final email = snap.data!.contactInfo.trim();
                        final subject =
                        Uri.encodeComponent('Inquiry about "${item.title}"');
                        final uri = Uri.parse('mailto:$email?subject=$subject');
                        try {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } catch (_) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Contact Owner',
                                  style: GoogleFonts.montserrat()),
                              content: SelectableText(email,
                                  style: GoogleFonts.lato()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close',
                                      style: GoogleFonts.lato()),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Contact Owner',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}