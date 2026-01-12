import 'package:amica/mainpage/widgets/verified_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/api_config.dart';
import '../provider/auth_provider.dart';
import '../provider/chat_provider.dart';
import 'connections_page.dart';
import 'user_profile_page.dart';
import 'group_invites_page.dart';
import 'group_banned_page.dart';
import '../models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupInfoPage extends StatefulWidget {
  final String chatId;
  const GroupInfoPage({super.key, required this.chatId});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  Map<String, dynamic>? _groupData;
  List<dynamic> _allMembers = [];
  List<dynamic> _filteredMembers = [];
  String _myRole = 'member';
  bool _allowMemberInvites = false;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final Color _scaffoldBg = Colors.black;
  final Color _blockBg = const Color(0xFF121212);
  final Color _primaryColor = Colors.blueAccent;
  final Color _dangerColor = Colors.redAccent;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMembers = _allMembers.where((m) {
        return m['display_name'].toLowerCase().contains(query) ||
            m['username'].toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await _chatService.getGroupDetails(widget.chatId);
      List<dynamic> sortedMembers = data['members'];

      sortedMembers.sort((a, b) {
        int getPriority(String role) {
          if (role == 'owner') return 0;
          if (role == 'admin') return 1;
          return 2;
        }

        return getPriority(a['role']).compareTo(getPriority(b['role']));
      });

      if (mounted) {
        setState(() {
          _groupData = data;
          _allMembers = sortedMembers;
          _filteredMembers = sortedMembers;
          _myRole = data['my_role'];
          _allowMemberInvites = data['allow_member_invites'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleInvitePermission(bool value) async {
    setState(() => _allowMemberInvites = value);
    try {
      await _chatService.updateGroupSettings(widget.chatId, value);
    } catch (e) {
      setState(() => _allowMemberInvites = !value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menyimpan pengaturan")),
      );
    }
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (picked != null) {
      setState(() => _isLoading = true);
      if (_groupData == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      await _chatService.updateGroupInfo(
        widget.chatId,
        _groupData!['name'],
        picked.path,
      );
      _fetchDetails();
    }
  }

  Future<void> _editGroupName() async {
    if (_groupData == null) return;
    final controller = TextEditingController(text: _groupData!['name']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _blockBg,
        title: const Text(
          "Ubah Nama Grup",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Nama baru",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await _chatService.updateGroupInfo(
                widget.chatId,
                controller.text,
                null,
              );
              _fetchDetails();
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _addMembers() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConnectionsPage(isSelectionMode: true),
      ),
    );

    if (result != null && result is User) {
      try {
        final res = await _chatService.addMembers(widget.chatId, [result.id]);

        _fetchDetails();

        String msg = res['message'];

        bool hasBanned = (res['banned'] as List).isNotEmpty;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: hasBanned ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        String err = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showInviteOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _blockBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Buat Tautan Undangan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text(
                "Tautan Standar",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Tidak ada batasan waktu",
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () => _generateAndCopyLink('permanent', ctx),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined, color: Colors.white),
              title: const Text(
                "Berlaku 24 Jam",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Tautan akan kadaluwarsa besok",
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () => _generateAndCopyLink('24h', ctx),
            ),
            ListTile(
              leading: const Icon(
                Icons.confirmation_number_outlined,
                color: Colors.white,
              ),
              title: const Text(
                "Sekali Pakai",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Hanya untuk 1 orang",
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () => _generateAndCopyLink('1x', ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndCopyLink(
    String type,
    BuildContext dialogContext,
  ) async {
    Navigator.pop(dialogContext);

    try {
      final url = await _chatService.generateInviteLink(widget.chatId, type);

      if (!mounted) return;

      Clipboard.setData(ClipboardData(text: url));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Link disalin!")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal membuat link")));
    }
  }

  void _showMemberOptions(dynamic member) {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (member['id'] == currentUser?.id) return;

    final bool isTargetOwner = member['role'] == 'owner';
    final bool isTargetAdmin = member['role'] == 'admin';
    final bool amIOwner = _myRole == 'owner';
    final bool amIAdmin = _myRole == 'admin';

    showModalBottomSheet(
      context: context,
      backgroundColor: _blockBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white),
            title: Text(
              "Lihat @${member['username']}",
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(userId: member['id']),
                ),
              );
            },
          ),
          if ((amIOwner || amIAdmin) && !isTargetOwner) ...[
            if (amIOwner || (amIAdmin && !isTargetAdmin)) ...[
              const Divider(color: Colors.grey),
              ListTile(
                leading: Icon(
                  isTargetAdmin ? Icons.arrow_downward : Icons.arrow_upward,
                  color: Colors.white,
                ),
                title: Text(
                  isTargetAdmin
                      ? "Jadikan Anggota Biasa"
                      : "Jadikan Admin Grup",
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _chatService.setMemberRole(
                    widget.chatId,
                    member['id'],
                    isTargetAdmin ? 'member' : 'admin',
                  );
                  _fetchDetails();
                },
              ),
              ListTile(
                leading: Icon(Icons.remove_circle_outline, color: _dangerColor),
                title: Text(
                  "Keluarkan (Kick)",
                  style: TextStyle(color: _dangerColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAction('kick', member);
                },
              ),
              ListTile(
                leading: Icon(Icons.block, color: _dangerColor),
                title: Text(
                  "Banned dari Grup",
                  style: TextStyle(color: _dangerColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAction('ban', member);
                },
              ),
            ],
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmAction(String action, dynamic member) {
    final isBan = action == 'ban';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _blockBg,
        title: Text(
          isBan ? "Banned User?" : "Keluarkan User?",
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isBan
              ? "${member['display_name']} akan dikeluarkan dan tidak bisa bergabung lagi."
              : "${member['display_name']} akan dikeluarkan.",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (isBan) {
                  await _chatService.banMember(widget.chatId, member['id']);
                } else {
                  await _chatService.kickMember(widget.chatId, member['id']);
                }
                _fetchDetails();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gagal memproses tindakan")),
                );
              }
            },
            child: Text(
              isBan ? "Banned" : "Keluarkan",
              style: TextStyle(color: _dangerColor),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuOption(String value) {
    switch (value) {
      case 'clear':
        context.read<ChatProvider>().clearChat(widget.chatId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chat dibersihkan untuk Anda")),
        );
        break;
    }
  }

  void _leaveGroup() async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _blockBg,
        title: const Text(
          "Keluar Grup?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Anda tidak akan bisa mengirim pesan lagi.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<ChatProvider>().leaveGroup(widget.chatId);
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _groupData == null) {
      return Scaffold(
        backgroundColor: _scaffoldBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isAdminOrOwner = _myRole == 'admin' || _myRole == 'owner';
    final imageUrl = ApiConfig.getFullUrl(_groupData?['image_url']);
    final canInvite = isAdminOrOwner || _allowMemberInvites;

    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: _blockBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Info Grup",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            color: _blockBg,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuOption,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text(
                  "Bersihkan Chat",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: _blockBg,
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: isAdminOrOwner ? _changePhoto : null,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey.shade800,
                          child: ClipOval(
                            child: imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                          Icons.groups,
                                          size: 60,
                                          color: Colors.white54,
                                        ),
                                  )
                                : const Icon(
                                    Icons.groups,
                                    size: 60,
                                    color: Colors.white54,
                                  ),
                          ),
                        ),
                        if (isAdminOrOwner)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _groupData?['name'] ?? "",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isAdminOrOwner)
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white,
                          ),
                          onPressed: _editGroupName,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Grup • ${_allMembers.length} Anggota",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (canInvite)
                        _buildActionButton(
                          Icons.link,
                          "Undang",
                          _showInviteOptions,
                        ),

                      const SizedBox(width: 16),

                      if (isAdminOrOwner)
                        _buildActionButton(
                          Icons.person_add,
                          "Tambah",
                          _addMembers,
                        ),

                      const SizedBox(width: 16),
                      _buildActionButton(Icons.search, "Cari", () {
                        setState(() {
                          _isSearching = !_isSearching;
                        });
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            if (isAdminOrOwner) ...[
              Container(
                color: _blockBg,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      secondary: const Icon(
                        Icons.group_add_outlined,
                        color: Colors.grey,
                      ),
                      title: const Text(
                        "Izinkan Member Mengundang",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: const Text(
                        "Member biasa bisa membuat link",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      value: _allowMemberInvites,
                      activeThumbColor: _primaryColor,
                      onChanged: _toggleInvitePermission,
                    ),
                    const Divider(height: 1, indent: 64, color: Colors.grey),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      leading: const Icon(
                        Icons.link_rounded,
                        color: Colors.grey,
                      ),
                      title: const Text(
                        "Kelola Tautan Undangan",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GroupInvitesPage(chatId: widget.chatId),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      leading: const Icon(Icons.block, color: Colors.red),
                      title: const Text(
                        "Daftar Diblokir",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GroupBannedPage(chatId: widget.chatId),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            Container(
              color: _blockBg,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "${_filteredMembers.length} PESERTA",
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Cari anggota...",
                          hintStyle: TextStyle(color: Colors.grey),
                          isDense: true,
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final m = _filteredMembers[index];
                      final avatar = ApiConfig.getFullUrl(m['avatar_url']);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        onTap: () => _showMemberOptions(m),
                        leading: CircleAvatar(
                          backgroundImage: avatar != null
                              ? NetworkImage(avatar)
                              : null,
                          backgroundColor: Colors.grey.shade800,
                          child: avatar == null
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                m['display_name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (m['is_verified'] == true)
                              const VerifiedBadge(size: 16),
                          ],
                        ),
                        subtitle: Text(
                          "@${m['username']}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        trailing: m['role'] != 'member'
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _primaryColor),
                                ),
                                child: Text(
                                  m['role'] == 'owner' ? "Owner" : "Admin",
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Container(
              color: _blockBg,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                leading: Icon(Icons.exit_to_app, color: _dangerColor),
                title: Text(
                  "Keluar dari Grup",
                  style: TextStyle(
                    color: _dangerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onTap: _leaveGroup,
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: _blockBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade800, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
