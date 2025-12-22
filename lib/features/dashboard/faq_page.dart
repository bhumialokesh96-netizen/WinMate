import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> faqs = [];
  bool isLoading = true;
  String selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    try {
      final query = supabase
          .from('faqs')
          .select()
          .order('priority', ascending: true)
          .order('created_at', ascending: false);

      final data = await query;
      setState(() {
        faqs = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      print("Error loading FAQs: $e");
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredFaqs {
    if (selectedCategory == 'all') return faqs;
    return faqs.where((faq) => faq['category'] == selectedCategory).toList();
  }

  List<String> get categories {
    final cats = faqs.map((faq) => faq['category'] as String).toSet().toList();
    cats.insert(0, 'all');
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Frequently Asked Questions"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category Filter
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            category == 'all' ? 'All' : category,
                            style: TextStyle(
                              color: selectedCategory == category
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          selected: selectedCategory == category,
                          selectedColor: Theme.of(context).primaryColor,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                // FAQs List
                Expanded(
                  child: filteredFaqs.isEmpty
                      ? const Center(
                          child: Text("No FAQs found for this category."),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredFaqs.length,
                          itemBuilder: (context, index) {
                            final faq = filteredFaqs[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ExpansionTile(
                                title: Text(
                                  faq['question'] ?? 'No Question',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: faq['category'] != null
                                    ? Chip(
                                        label: Text(
                                          faq['category'].toString(),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity:
                                            VisualDensity.compact,
                                      )
                                    : null,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      faq['answer'] ?? 'No Answer',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
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
