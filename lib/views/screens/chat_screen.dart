import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import '../../viewmodels/chat_view_model.dart';
import '../../services/model_manager.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMsgCount = 0;
  String? _lastSessionId;
  bool _showScrollBtn = false;

  @override
  void initState() {
    super.initState();
    final vm = context.read<ChatViewModel>();
    _lastMsgCount = vm.messages.length;
    _lastSessionId = vm.currentSession?.id;
    vm.addListener(_onVmChanged);

    _scrollController.addListener(() {
      final show = _scrollController.hasClients &&
          _scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200;
      if (show != _showScrollBtn) setState(() => _showScrollBtn = show);
    });
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _onVmChanged() {
    if (!mounted) return;
    final vm = context.read<ChatViewModel>();
    final sessionChanged = _lastSessionId != vm.currentSession?.id;
    final messageAdded = vm.messages.length > _lastMsgCount;

    _lastSessionId = vm.currentSession?.id;
    _lastMsgCount = vm.messages.length;

    if (sessionChanged || messageAdded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    try {
      context.read<ChatViewModel>().removeListener(_onVmChanged);
    } catch (_) {}
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _formatAiText(String text) {
    // Fix missing newlines before tables
    text = text.replaceAll(': |', ':\n\n|');
    text = text.replaceAll('. |', '.\n\n|');
    // Fix missing newlines between table rows
    text = text.replaceAll(' | | ', ' |\n| ');
    text = text.replaceAll('||', '|\n|');
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isReady = context.watch<ModelManager>().isReady;
    final vm = context.watch<ChatViewModel>();
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: isReady ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('AI Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            if (vm.currentSession != null)
              Text(
                vm.currentSession!.title,
                style: TextStyle(
                  fontSize: 10,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          Consumer<ChatViewModel>(builder: (context, vm, _) {
            if (!vm.hasMessages) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Clear Conversation',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: colors.surface,
                    content: const Text('Clear entire conversation?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () { Navigator.pop(ctx); vm.clearConversation(); },
                        child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: colors.surface,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.brand, size: 24),
                    const SizedBox(width: 12),
                    Text('Velo Chat', style: AppTextStyles.heading2),
                  ],
                ),
              ),
              Divider(color: colors.border, height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    vm.createNewSession();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.brandGradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: colors.textOnBrand, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'New Chat',
                          style: AppTextStyles.labelLarge.copyWith(color: colors.textOnBrand),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CONVERSATIONS',
                    style: AppTextStyles.labelSmall.copyWith(color: colors.textTertiary),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: vm.sessions.length,
                  itemBuilder: (ctx, idx) {
                    final session = vm.sessions[idx];
                    final isSelected = vm.currentSession?.id == session.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brand.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.brand.withValues(alpha: 0.2) : Colors.transparent,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          dense: true,
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            color: isSelected ? AppColors.brand : colors.textSecondary,
                            size: 18,
                          ),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: isSelected
                                ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.brand)
                                : AppTextStyles.bodyMedium,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            vm.selectSession(session.id);
                          },
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, size: 16, color: colors.textTertiary),
                            onPressed: () {
                              _confirmDeleteSession(context, vm, session);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<ChatViewModel>(builder: (context, vm, _) {
        return Stack(
          children: [
            Column(
              children: [
                _modeToggle(vm, colors),
                Expanded(
                  child: vm.messages.isEmpty
                      ? _emptyState(vm, colors)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: vm.messages.length,
                          itemBuilder: (context, i) => _messageBubble(vm.messages[i], i, vm.messages, colors),
                        ),
                ),
                _quickChips(vm, colors),
                _buildInputBar(vm, colors),
              ],
            ),
            if (_showScrollBtn)
              Positioned(
                right: 20,
                bottom: 80,
                child: GestureDetector(
                  onTap: _scrollToBottom,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.cardElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(Icons.keyboard_arrow_down, color: colors.textPrimary, size: 20),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _emptyState(ChatViewModel vm, AppColorSet colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.brandGradient),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.25),
                    blurRadius: 20, offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.chat_bubble_rounded, color: colors.textOnBrand, size: 32),
            ),
            const SizedBox(height: 24),
            Text('Velo AI Assistant', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Chat with AI about your finances, analyze spending, review budgets, or ask \"Can I afford it?\". Add receipts using the + button.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(ChatMessage msg, int index, List<ChatMessage> all, AppColorSet colors) {
    final isUser = msg.type == MessageType.user;
    final isFirst = index == 0 || all[index - 1].type != msg.type;
    final showTime = isFirst || index == all.length - 1;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 4 : 2),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && isFirst)
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.brandGradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_awesome, size: 16, color: colors.textOnBrand),
            ),
          if (!isUser && isFirst) const SizedBox(width: 8),
          if (!isUser && !isFirst) const SizedBox(width: 40),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.brand.withValues(alpha: 0.15) : colors.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : (isFirst ? 4 : 18)),
                      bottomRight: Radius.circular(isUser ? (isFirst ? 4 : 18) : 18),
                    ),
                    border: Border.all(
                      color: isUser ? AppColors.brand.withValues(alpha: 0.2) : colors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.hasImage && msg.imagePath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(msg.imagePath!),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 100, color: colors.surfaceAlt,
                              child: Center(child: Icon(Icons.broken_image, color: colors.textTertiary)),
                            ),
                          ),
                        ),
                      if (msg.hasImage && msg.imagePath != null) const SizedBox(height: 10),
                      if (msg.content.isNotEmpty)
                        isUser
                            ? Text(msg.content, style: AppTextStyles.bodyLarge)
                            : MarkdownBody(
                                data: _formatAiText(msg.content),
                                extensionSet: md.ExtensionSet.gitHubFlavored,
                                styleSheet: MarkdownStyleSheet(
                                  p: AppTextStyles.bodyLarge,
                                  a: const TextStyle(color: AppColors.brand),
                                  code: const TextStyle(color: AppColors.accent, fontSize: 13),
                                  codeblockDecoration: BoxDecoration(
                                    color: colors.surfaceAlt, borderRadius: BorderRadius.circular(8),
                                  ),
                                  blockquoteDecoration: BoxDecoration(
                                    color: AppColors.brand.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  h1: AppTextStyles.heading1,
                                  h2: AppTextStyles.heading2,
                                  h3: AppTextStyles.heading3,
                                  listBullet: AppTextStyles.bodyLarge,
                                  strong: AppTextStyles.labelLarge,
                                ),
                              ),
                    ],
                  ),
                ),
                if (showTime)
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: isUser ? 0 : 0, right: isUser ? 4 : 0),
                    child: Text(
                      DateFormat('h:mm a').format(msg.timestamp),
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser && isFirst) const SizedBox(width: 8),
          if (isUser && isFirst)
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person, size: 18, color: colors.textSecondary),
            ),
          if (isUser && !isFirst) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _modeToggle(ChatViewModel vm, AppColorSet colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => vm.toggleAssistantMode('standard'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: vm.assistantMode == 'standard' ? AppColors.brand : colors.surfaceAlt,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                ),
                child: Center(
                  child: Text('Standard',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: vm.assistantMode == 'standard' ? colors.textOnBrand : colors.textSecondary)),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => vm.toggleAssistantMode('roast'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: vm.assistantMode == 'roast' ? AppColors.warning : colors.surfaceAlt,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                ),
                child: Center(
                  child: Text('Roast Me',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: vm.assistantMode == 'roast' ? Colors.black : colors.textSecondary)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChips(ChatViewModel vm, AppColorSet colors) {
    if (vm.messages.isNotEmpty) return const SizedBox.shrink();
    final chips = [
      'Can I afford a \$500 purchase?',
      'Review my spending this month',
      'Roast my expenses 🔥',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips.map((chip) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  vm.sendMessage(chip);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                  ),
                  child: Text(chip, style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputBar(ChatViewModel vm, AppColorSet colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.5))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: vm.isGenerating ? null : _showImageSourceSheet,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_photo_alternate_outlined, color: colors.textSecondary, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: vm.isGenerating ? 'AI is thinking...' : 'Ask about your finances...',
                  filled: true,
                  fillColor: colors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(vm),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: vm.isGenerating || _controller.text.trim().isEmpty
                  ? null
                  : () => _sendMessage(vm),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: (_controller.text.trim().isNotEmpty && !vm.isGenerating)
                      ? const LinearGradient(colors: AppColors.brandGradient)
                      : null,
                  color: (_controller.text.trim().isEmpty || vm.isGenerating)
                      ? colors.surfaceAlt
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: vm.isGenerating
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textOnBrand,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: (_controller.text.trim().isNotEmpty && !vm.isGenerating)
                            ? colors.textOnBrand
                            : colors.textTertiary,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(ChatViewModel vm) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    vm.sendMessage(text);
    _scrollToBottom();
  }

  void _showImageSourceSheet() {
    final vm = context.read<ChatViewModel>();
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Attach a Photo', style: AppTextStyles.heading2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _sourceBtn(
                      colors: colors,
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final path = await vm.takePhoto();
                        if (path != null) {
                          final text = _controller.text.trim();
                          _controller.clear();
                          await vm.sendMultimodalMessage(
                            text.isEmpty ? 'Analyze this financial document or receipt and extract any relevant transaction details.' : text,
                            path,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sourceBtn(
                      colors: colors,
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final path = await vm.pickImage();
                        if (path != null) {
                          final text = _controller.text.trim();
                          _controller.clear();
                          await vm.sendMultimodalMessage(
                            text.isEmpty ? 'Analyze this financial document or receipt and extract any relevant transaction details.' : text,
                            path,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceBtn({required AppColorSet colors, required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.textPrimary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.labelLarge),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSession(BuildContext context, ChatViewModel vm, ChatSession session) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        content: Text('Delete conversation "${session.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.deleteSession(session.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
