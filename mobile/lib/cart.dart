import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'cart_manager.dart';
import 'takeout.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color darkGrey = const Color(0xFF4A4D4A);
  final Color textDark = const Color(0xFF2C3028);
  final Color lightCream = const Color(0xFFEBE5D9);
  
  // URL untuk memanggil gambar dari backend (FIX ISSUE 2)
  String get baseUrl => kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000'; 

  @override
  void initState() {
    super.initState();
    CartManager.instance.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartManager.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  String _formatRp(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}';
  }

  int _calculateItemTotal(Map<String, dynamic> item) {
    int price = 0;
    if (item['basePrice'] is num) {
      price = (item['basePrice'] as num).toInt();
    } else if (item['price'] is num) {
      price = (item['price'] as num).toInt();
    }
    
    Map<String, int> addonOpts = {};
    if (item['addonOptions'] is Map) {
      (item['addonOptions'] as Map).forEach((k, v) {
        addonOpts[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }

    final List<String> currentAddons = List<String>.from(item['selectedAddons'] ?? []);

    for (var addon in currentAddons) {
      price += addonOpts[addon] ?? 0;
    }
    return price * (int.tryParse(item['quantity'].toString()) ?? 1);
  }

  // --------------------------------------------------------------------------
  // MODIFIER SHEET (FIX ISSUE 3: UI disamakan dengan Menu Page & Responsif)
  // --------------------------------------------------------------------------
  void _showModifierSheet(BuildContext context, int index, Map<String, dynamic> item) {
    // Pull every customization axis off the cart entry:
    //   • preferenceGroups → new multi-axis map (Ice Level / Sugar Level / …)
    //   • spiceOptions     → legacy single-axis chip list
    //   • spice_level_max  → very old numeric slider
    //   • addonOptions     → priced add-ons
    final Map<String, List<String>> prefGroups = (item['preferenceGroups'] as Map?)
        ?.map((k, v) => MapEntry(k.toString(), List<String>.from((v as List).map((x) => x.toString())))) ?? {};
    final Map<String, String> selectedPrefs = Map<String, String>.from(
      (item['selectedPreferences'] as Map?)?.cast<String, String>() ?? <String, String>{},
    );

    final List<String> spiceOpts = List<String>.from(item['spiceOptions'] ?? []);
    String selectedSpiceStr = (item['selectedSpice'] ?? '').toString();

    int currentSpiceLevel = 0;
    if (item['selectedSpice'] is int) {
      currentSpiceLevel = item['selectedSpice'];
    }
    int maxSpice = 0;
    if (item['spice_level_max'] is num) {
      maxSpice = (item['spice_level_max'] as num).toInt();
    } else if (item['spice_max'] is num) {
      maxSpice = (item['spice_max'] as num).toInt();
    }

    List<String> currentAddons = List<String>.from(item['selectedAddons'] ?? []);

    Map<String, int> addonOpts = {};
    if (item['addonOptions'] is Map) {
      (item['addonOptions'] as Map).forEach((k, v) {
        addonOpts[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }

    int basePrice = 0;
    if (item['basePrice'] is num) {
      basePrice = (item['basePrice'] as num).toInt();
    } else if (item['price'] is num) {
      basePrice = (item['price'] as num).toInt();
    }

    int qty = int.tryParse(item['quantity'].toString()) ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int tempSubtotal = basePrice;
            for (var addon in currentAddons) {
              tempSubtotal += addonOpts[addon] ?? 0;
            }
            int displayTotal = tempSubtotal * qty;

            final bool hasAnyOption =
                prefGroups.isNotEmpty || spiceOpts.isNotEmpty || addonOpts.isNotEmpty || maxSpice > 0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24, left: 24, right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Modify ${item['name']}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 20),

                    if (!hasAnyOption)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "This item has no customization options.",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),

                    // NEW: render every preference axis as its own chip group.
                    ...prefGroups.entries.map((entry) {
                      final groupLabel = entry.key;
                      final opts = entry.value;
                      if (opts.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(groupLabel.toUpperCase(),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryGreen)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: opts.map<Widget>((opt) {
                                final bool isSel = selectedPrefs[groupLabel] == opt;
                                return ChoiceChip(
                                  label: Text(opt,
                                    style: TextStyle(
                                      color: isSel ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold, fontSize: 12,
                                    )),
                                  selected: isSel,
                                  selectedColor: primaryGreen,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: primaryGreen.withOpacity(0.4)),
                                  ),
                                  onSelected: (_) => setModalState(() {
                                    selectedPrefs[groupLabel] = opt;
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    if (prefGroups.isEmpty && spiceOpts.isNotEmpty) ...[
                      Text("PREFERENCES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryGreen)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: spiceOpts.map<Widget>((opt) {
                          final bool isSel = selectedSpiceStr == opt;
                          return ChoiceChip(
                            label: Text(
                              opt,
                              style: TextStyle(
                                color: isSel ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: primaryGreen,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: primaryGreen.withOpacity(0.4)),
                            ),
                            onSelected: (val) {
                              setModalState(() => selectedSpiceStr = opt);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (prefGroups.isEmpty && spiceOpts.isEmpty && maxSpice > 0) ...[
                      Text("SPICE LEVEL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryGreen)),
                      const SizedBox(height: 8),
                      Slider(
                        value: currentSpiceLevel.toDouble(),
                        min: 0,
                        max: maxSpice.toDouble(),
                        divisions: maxSpice > 0 ? maxSpice : 1,
                        activeColor: primaryGreen,
                        label: currentSpiceLevel == 0 ? "Normal" : "Level $currentSpiceLevel",
                        onChanged: (val) {
                          setModalState(() => currentSpiceLevel = val.toInt());
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Opsi Add-ons (Jika ada)
                    if (addonOpts.isNotEmpty) ...[
                      Text("ADD-ONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryGreen)),
                      const SizedBox(height: 8),
                      ...addonOpts.keys.map((addonKey) {
                        bool hasAddon = currentAddons.contains(addonKey);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(addonKey, style: TextStyle(color: textDark, fontWeight: FontWeight.w500, fontSize: 15)),
                          subtitle: Text("+ ${_formatRp(addonOpts[addonKey] ?? 0)}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          value: hasAddon,
                          activeColor: primaryGreen,
                          onChanged: (checked) {
                            setModalState(() {
                              if (checked == true) {
                                currentAddons.add(addonKey);
                              } else {
                                currentAddons.remove(addonKey);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () {
                        // Persist every axis back onto the cart entry.
                        if (prefGroups.isNotEmpty) {
                          item['selectedPreferences'] = selectedPrefs;
                        }
                        if (spiceOpts.isNotEmpty) {
                          item['selectedSpice'] = selectedSpiceStr;
                        } else if (maxSpice > 0) {
                          item['selectedSpice'] = currentSpiceLevel;
                        }
                        item['selectedAddons'] = currentAddons;
                        CartManager.instance.updateQuantity(index, qty);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Apply Changes - ${_formatRp(displayTotal)}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = CartManager.instance.items;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // FIX ISSUE 1: Berubah jadi My Cart
        title: const Text('My Cart', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Your cart is empty", style: TextStyle(color: darkGrey, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                
                // FIX ISSUE 2: Handling Image Url (Menambahkan baseUrl)
                String rawImg = (item['image_url'] ?? item['img'] ?? '').toString();
                String imageUrl = '';
                bool isAsset = false;

                if (rawImg.isNotEmpty) {
                  if (rawImg.startsWith('http')) {
                    imageUrl = rawImg;
                  } else if (rawImg.startsWith('assets/')) {
                    isAsset = true;
                    imageUrl = rawImg;
                  } else {
                    imageUrl = rawImg.startsWith('/') ? '$baseUrl$rawImg' : '$baseUrl/$rawImg';
                  }
                }
                    
                final List<String> addons = List<String>.from((item['selectedAddons'] as List?) ?? []);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ------------------------------------------------------------
                      // UPDATE 3: GAMBAR PRODUK & "Review Order" Text View Below It
                      // ------------------------------------------------------------
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl.isNotEmpty
                                ? (isAsset 
                                    ? Image.asset(
                                        imageUrl,
                                        width: 75, height: 75, fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 75, height: 75, color: lightCream,
                                          child: Icon(Icons.broken_image, color: primaryGreen),
                                        ),
                                      )
                                    : Image.network(
                                        imageUrl,
                                        width: 75, height: 75, fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 75, height: 75, color: lightCream,
                                          child: Icon(Icons.broken_image, color: primaryGreen),
                                        ),
                                      ))
                                : Container(
                                    width: 75, height: 75, color: lightCream,
                                    child: Icon(Icons.image, color: primaryGreen),
                                  ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      const SizedBox(width: 12),
                      
                      // DETAIL PRODUK (Nama, Addons, Harga & Kontrol)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Baris Atas: Judul & Tombol QTY (+/-)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['name'] ?? 'Unknown Item',
                                    style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                // Tombol Tambah Kurang (QTY)
                                Container(
                                  decoration: BoxDecoration(
                                    color: lightCream,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 16),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        onPressed: () {
                                          CartManager.instance.updateQuantity(index, (item['quantity'] as int) - 1);
                                        },
                                      ),
                                      Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 16),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        onPressed: () {
                                          CartManager.instance.updateQuantity(index, (item['quantity'] as int) + 1);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Baris Tengah: Addons & Harga
                            if (addons.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 4),
                                child: Text(
                                  addons.join(', '),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRp(_calculateItemTotal(item)),
                              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Baris Bawah: Tombol EDIT & TRASH BIN
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () => _showModifierSheet(context, index, item),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit, size: 16, color: primaryGreen),
                                        const SizedBox(width: 4),
                                        Text("Edit", style: TextStyle(color: primaryGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                
                                InkWell(
                                  onTap: () {
                                    CartManager.instance.removeAt(index);
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      // BAGIAN BAWAH (Subtotal & Next Button)
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Total Pesanan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _formatRp(CartManager.instance.subtotal),
                          style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TakeoutPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Row(
                        children: [
                          Text("Next", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}