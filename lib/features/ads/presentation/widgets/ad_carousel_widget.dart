import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/ad_model.dart';
import '../providers/ad_provider.dart';

class AdCarouselWidget extends StatefulWidget {
  const AdCarouselWidget({super.key});

  @override
  State<AdCarouselWidget> createState() => _AdCarouselWidgetState();
}

class _AdCarouselWidgetState extends State<AdCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AdProvider>();
      provider.fetchAds().then((_) {
        if (!mounted) return;
        _startAutoScroll(provider.adsList);
      });
    });
  }

  void _startAutoScroll(List<AdModel> ads) {
    if (ads.length > 1) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_pageController.hasClients) {
          final nextPage = (_currentPage + 1) % ads.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Widget _buildAdImage(String imageUrl, String docId) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdProvider>();
    final ads = provider.adsList;

    if (provider.isLoading) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF8B1E2D))),
      );
    }

    // Default premium fallback banners if database has no ads
    final List<AdModel> displayAds = ads.isNotEmpty
        ? ads
        : [
            AdModel(
              id: 'mock_ad_1',
              imageUrl: 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?q=80&w=600&auto=format&fit=crop',
              createdAt: DateTime.now().toIso8601String(),
            ),
            AdModel(
              id: 'mock_ad_2',
              imageUrl: 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?q=80&w=600&auto=format&fit=crop',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ];

    final overlayTitles = [
      'KGRA State Conference',
      'KGRA Official Portal',
      'Professional Excellence',
    ];

    final overlaySubtitles = [
      'Empowering Kerala Radiographers',
      'All services & orders in one place',
      'Together for the Profession',
    ];

    return Column(
      children: [
        Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemCount: displayAds.length,
                  itemBuilder: (context, index) {
                    final ad = displayAds[index];
                    final title = overlayTitles[index % overlayTitles.length];
                    final subtitle = overlaySubtitles[index % overlaySubtitles.length];

                    return GestureDetector(
                      onTap: () async {
                        if (ad.targetUrl != null && ad.targetUrl!.trim().isNotEmpty) {
                          final uri = Uri.parse(ad.targetUrl!.trim());
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Base Ad Image
                          _buildAdImage(ad.imageUrl, ad.id),
                          
                          // Dark bottom overlay gradient for text legibility
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black87,
                                  Colors.black38,
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                stops: [0.0, 0.4, 0.95],
                              ),
                            ),
                          ),

                          // Text Content
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Logo Overlay in top-right corner
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/kgra.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFF8B1E2D),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Indicator dots overlay
                Positioned(
                  bottom: 12,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      displayAds.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == index ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
