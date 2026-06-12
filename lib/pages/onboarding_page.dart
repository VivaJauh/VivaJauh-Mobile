import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.onCompleted, super.key});

  final VoidCallback onCompleted;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final controller = PageController();
  var index = 0;

  final items = const [
    OnboardingItem(
      image: 'assets/images/onboarding_farm.jpg',
      title: 'Operasional koperasi tetap jalan',
      body:
          'Catat pakan, ternak, simpanan, dan laporan harian langsung dari lapangan walau sinyal tidak stabil.',
    ),
    OnboardingItem(
      image: 'assets/images/onboarding_harvest.jpg',
      title: 'Data aman di perangkat',
      body:
          'Setiap input masuk antrean lokal dengan waktu pencatatan asli dan kunci sinkronisasi agar tidak dobel.',
    ),
    OnboardingItem(
      image: 'assets/images/onboarding_tractor.jpg',
      title: 'Sinkron saat jaringan kembali',
      body:
          'Data dikirim ke server VivaJauh untuk validasi tenant, verifikasi admin, dan laporan resmi koperasi.',
    ),
  ];

  void previousPage() {
    if (index == 0) return;
    controller.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void goToPage(int pageIndex) {
    controller.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: index == 0
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: previousPage,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: items.length,
                  onPageChanged: (value) => setState(() => index = value),
                  itemBuilder: (context, pageIndex) =>
                      OnboardingCard(item: items[pageIndex]),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (dotIndex) => GestureDetector(
                    onTap: () => goToPage(dotIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: dotIndex == index ? 30 : 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: dotIndex == index
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  if (index == items.length - 1) {
                    widget.onCompleted();
                    return;
                  }
                  controller.nextPage(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                  );
                },
                child: Text(index == items.length - 1 ? 'Masuk' : 'Lanjut'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingCard extends StatelessWidget {
  const OnboardingCard({required this.item, super.key});

  final OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(item.image, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(10),
                        Colors.black.withAlpha(135),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          item.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item.body,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.muted, height: 1.5),
        ),
      ],
    );
  }
}

class OnboardingItem {
  const OnboardingItem({
    required this.image,
    required this.title,
    required this.body,
  });

  final String image;
  final String title;
  final String body;
}
