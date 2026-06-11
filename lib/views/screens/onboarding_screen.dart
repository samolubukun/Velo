import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../viewmodels/onboarding_view_model.dart';
import '../../utils/number_formatter.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, vm, _) => _OnboardingBody(vm: vm),
    );
  }
}

class _OnboardingBody extends StatefulWidget {
  final OnboardingViewModel vm;
  const _OnboardingBody({required this.vm});

  @override
  State<_OnboardingBody> createState() => _OnboardingBodyState();
}

class _OnboardingBodyState extends State<_OnboardingBody> {
  final _nameCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController(text: 'Current Account');
  final _balanceCtrl = TextEditingController(text: '1000');
  final _savingsCtrl = TextEditingController(text: '500');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accountNameCtrl.dispose();
    _balanceCtrl.dispose();
    _savingsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final vm = widget.vm;

    return Scaffold(
      backgroundColor: colors.scaffold,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.8),
                  radius: 1.2,
                  colors: [
                    AppColors.brand.withValues(alpha: 0.12),
                    colors.scaffold,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Step indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(vm.totalSteps, (i) {
                    final active = i == vm.currentStep;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.brand
                            : AppColors.brand.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // Page content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(vm.currentStep),
                      child: _buildStep(context, colors, vm),
                    ),
                  ),
                ),

                // Nav buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Row(
                    children: [
                      if (vm.currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: vm.previousStep,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textSecondary,
                              side: BorderSide(color: colors.border),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                      if (vm.currentStep > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _onNext(context, vm),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            vm.currentStep == vm.totalSteps - 1
                                ? 'Get Started'
                                : 'Continue',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onNext(BuildContext context, OnboardingViewModel vm) async {
    if (vm.currentStep == vm.totalSteps - 1) {
      await vm.completeOnboarding();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/model-setup');
      }
    } else {
      vm.nextStep();
    }
  }

  Widget _buildStep(
      BuildContext context, AppColorSet colors, OnboardingViewModel vm) {
    switch (vm.currentStep) {
      case 0:
        return _StepWelcome(colors: colors);
      case 1:
        return _StepName(ctrl: _nameCtrl, vm: vm, colors: colors);
      case 2:
        return _StepCurrencyGoal(ctrl: _savingsCtrl, vm: vm, colors: colors);
      case 3:
        return _StepFirstAccount(
          nameCtrl: _accountNameCtrl,
          balanceCtrl: _balanceCtrl,
          vm: vm,
          colors: colors,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────── Steps ───────────────────────────────

class _StepWelcome extends StatelessWidget {
  final AppColorSet colors;
  const _StepWelcome({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      children: [
        Center(
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.35),
                  blurRadius: 30, offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/icons/velo_app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        ),
  
        const SizedBox(height: 32),
        Text('Welcome to Velo',
            style: AppTextStyles.displaySmall
                .copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center)
            .animate().fadeIn(delay: 200.ms, duration: 500.ms),
  
        const SizedBox(height: 12),
        Text(
          'Secure finance meets offline intelligence.\nYour money, your device, your business.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(color: colors.textSecondary),
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
  
        const SizedBox(height: 32),
        _FeatureRow(icon: Icons.lock_outline, label: '100% offline — zero cloud'),
        _FeatureRow(icon: Icons.smart_toy_outlined, label: 'On-device AI with Gemma 4'),
        _FeatureRow(icon: Icons.receipt_long_outlined, label: 'Receipt & PDF bank statement import'),
        _FeatureRow(icon: Icons.bar_chart_rounded, label: 'Financial health scoring'),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brand, size: 18),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _StepName extends StatelessWidget {
  final TextEditingController ctrl;
  final OnboardingViewModel vm;
  final AppColorSet colors;
  const _StepName({required this.ctrl, required this.vm, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What should we call you?', style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            Text('Your name stays on your device only.',
                style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary)),
            const SizedBox(height: 32),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: vm.setName,
              decoration: const InputDecoration(
                hintText: 'e.g. Alex',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCurrencyGoal extends StatelessWidget {
  final TextEditingController ctrl;
  final OnboardingViewModel vm;
  final AppColorSet colors;
  const _StepCurrencyGoal(
      {required this.ctrl, required this.vm, required this.colors});

  static const _currencies = ['USD', 'EUR', 'GBP', 'TRY', 'NGN', 'CAD', 'AUD'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Currency & Savings Goal', style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            Text('Choose your base currency and monthly savings target.',
                style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary)),
            const SizedBox(height: 32),
  
            Text('Base Currency', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: DropdownButton<String>(
                value: vm.baseCurrency,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                dropdownColor: colors.surface,
                items: _currencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) { if (v != null) vm.setBaseCurrency(v); },
              ),
            ),
  
            const SizedBox(height: 24),
            Text('Monthly Savings Goal', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              onChanged: (v) => vm.setMonthlySavingsGoal(NumberFormatter.parseAmount(v)),
              decoration: InputDecoration(
                hintText: '500',
                prefixText: '${vm.baseCurrency} ',
                prefixIcon: const Icon(Icons.savings_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepFirstAccount extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController balanceCtrl;
  final OnboardingViewModel vm;
  final AppColorSet colors;
  const _StepFirstAccount(
      {required this.nameCtrl, required this.balanceCtrl, required this.vm, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Up Your First Account', style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            Text('You can add more accounts later from the Dashboard.',
                style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary)),
            const SizedBox(height: 32),
  
            Text('Account Name', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: vm.setInitialAccountName,
              decoration: const InputDecoration(
                hintText: 'Current Account',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
  
            const SizedBox(height: 20),
            Text('Opening Balance', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            TextField(
              controller: balanceCtrl,
              keyboardType: TextInputType.number,
              onChanged: (v) => vm.setInitialAccountBalance(NumberFormatter.parseAmount(v)),
              decoration: InputDecoration(
                hintText: '1000',
                prefixText: '${vm.baseCurrency} ',
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
