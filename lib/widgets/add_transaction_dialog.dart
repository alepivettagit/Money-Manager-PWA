import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../providers/category_provider.dart';
import '../services/gemini_receipt_service.dart';
import 'manage_categories_sheet.dart';

class AddTransactionSheet extends StatefulWidget {
  final String accountId;
  final DateTime? initialDate;
  final Function(Transaction)? onAdd;
  final Transaction? transactionToEdit;
  final Function(Transaction)? onUpdate;
  final VoidCallback? onDelete;
  final double? initialAmount;
  final String? initialTitle;
  final String? initialCategory;
  final String? initialNote;
  final TransactionType? initialType;

  const AddTransactionSheet({
    super.key,
    required this.accountId,
    this.initialDate,
    this.onAdd,
    this.transactionToEdit,
    this.onUpdate,
    this.onDelete,
    this.initialAmount,
    this.initialTitle,
    this.initialCategory,
    this.initialNote,
    this.initialType,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isScanning = false;

  bool get _isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    final editTx = widget.transactionToEdit;
    if (editTx != null) {
      _type = editTx.type;
      _selectedCategory = editTx.category;
      _selectedDate = editTx.date;
      _amountController.text = editTx.amount.toStringAsFixed(
        editTx.amount.truncateToDouble() == editTx.amount ? 0 : 2,
      );
      _titleController.text = editTx.title;
      _noteController.text = editTx.note ?? '';
    } else {
      _type = widget.initialType ?? TransactionType.expense;
      _selectedCategory =
          widget.initialCategory ??
          (_type == TransactionType.expense
              ? TransactionCategories.expenseCategories.first.name
              : TransactionCategories.incomeCategories.first.name);
      _selectedDate = widget.initialDate ?? DateTime.now();
      if (widget.initialAmount != null) {
        _amountController.text = widget.initialAmount!.toStringAsFixed(
          widget.initialAmount!.truncateToDouble() == widget.initialAmount
              ? 0
              : 2,
        );
      }
      if (widget.initialTitle != null) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialNote != null) {
        _noteController.text = widget.initialNote!;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickAndAnalyzeReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Acquisisci Scontrino con IA',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF10B981),
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Scatta con Fotocamera',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Inquadra chiaramente data, negozio e totale',
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              const SizedBox(height: 6),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF0F172A),
                  child: Icon(Icons.photo_library_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Carica da Galleria o File',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Scegli una foto già salvata'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (photo == null || !mounted) return;

    final customCategories = context.read<CategoryProvider>().getCategoryNames(
      TransactionType.expense,
    );

    setState(() => _isScanning = true);

    try {
      final bytes = await photo.readAsBytes();
      final mimeType = photo.mimeType ?? 'image/jpeg';
      final result = await GeminiReceiptService.instance.analyzeReceipt(
        imageBytes: bytes,
        mimeType: mimeType,
        customCategories: customCategories,
      );

      if (!mounted) return;

      setState(() {
        _type = TransactionType.expense;
        if (result.total != null) {
          _amountController.text = result.total!.toStringAsFixed(
            result.total!.truncateToDouble() == result.total ? 0 : 2,
          );
        }
        if (result.merchant != null && result.merchant!.isNotEmpty) {
          _titleController.text = result.merchant!;
        }
        if (result.category.isNotEmpty) {
          _selectedCategory = result.category;
        }
        if (result.date != null) {
          _selectedDate = result.date!;
        }
        if (result.itemsSummary != null && result.itemsSummary!.isNotEmpty) {
          _noteController.text = result.itemsSummary!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Scontrino analizzato con successo!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore: ${e.toString().replaceAll("Exception: ", "")}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _onTypeChanged(TransactionType newType) {
    final catProvider = context.read<CategoryProvider>();
    final newCategories = catProvider.getCategories(newType);
    setState(() {
      _type = newType;
      _selectedCategory = newCategories.isNotEmpty
          ? newCategories.first.name
          : (newType == TransactionType.expense ? 'Spesa e Cibo' : 'Stipendio');
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina Movimento'),
        content: Text(
          'Sei sicuro di voler eliminare "${widget.transactionToEdit!.title}" da €${widget.transactionToEdit!.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // Chiudi alert
              Navigator.of(context).pop(); // Chiudi bottom sheet
              widget.onDelete?.call();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final amountText = _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un importo valido maggiore di 0'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? _selectedCategory
        : _titleController.text.trim();

    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    if (_isEditing) {
      final updatedTransaction = widget.transactionToEdit!.copyWith(
        title: title,
        amount: amount,
        date: _selectedDate,
        type: _type,
        category: _selectedCategory,
        note: note,
      );
      widget.onUpdate?.call(updatedTransaction);
    } else {
      final newTransaction = Transaction(
        id: const Uuid().v4(),
        accountId: widget.accountId,
        title: title,
        amount: amount,
        date: _selectedDate,
        type: _type,
        category: _selectedCategory,
        note: note,
      );
      widget.onAdd?.call(newTransaction);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == TransactionType.expense;
    final catProvider = context.watch<CategoryProvider>();
    final categories = catProvider.getCategories(_type);
    final dateFormat = DateFormat('dd MMM yyyy', 'it_IT');

    if (categories.isNotEmpty &&
        !categories.any((c) => c.name == _selectedCategory)) {
      _selectedCategory = categories.first.name;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isEditing && widget.onDelete != null
                    ? const SizedBox(width: 48)
                    : const SizedBox(width: 8),
                Text(
                  _isEditing ? 'Modifica Movimento' : 'Nuova Transazione',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isEditing && widget.onDelete != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                    ),
                    tooltip: 'Elimina Movimento',
                    onPressed: _confirmDelete,
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),

            if (!_isEditing) ...[
              OutlinedButton.icon(
                onPressed: _isScanning ? null : _pickAndAnalyzeReceipt,
                icon: _isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF10B981),
                        ),
                      )
                    : const Icon(
                        Icons.document_scanner_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                label: Text(
                  _isScanning
                      ? 'Analisi IA con Gemini in corso...'
                      : 'Scansiona Scontrino con IA',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: const Color(0xFF10B981).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: const Color(0xFF10B981)
                      .withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Tipo: Spesa / Entrata
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.expense),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isExpense
                              ? const Color(0xFFEF4444)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Spesa',
                            style: TextStyle(
                              color: isExpense
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.income),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isExpense
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Entrata',
                            style: TextStyle(
                              color: !isExpense
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Importo
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isExpense
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixText: '€ ',
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Titolo / Descrizione
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Descrizione',
                hintText: isExpense
                    ? 'Es. Pranzo fuori, Spesa...'
                    : 'Es. Stipendio, Rimborso...',
                prefixIcon: const Icon(Icons.edit_note_rounded),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Note opzionali
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note aggiuntive (opzionale)',
                hintText: 'Es. Dettagli, ricevuta o luogo...',
                prefixIcon: const Icon(Icons.notes_rounded),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Categoria
            const Text(
              'Categoria',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == categories.length) {
                    return ActionChip(
                      avatar: const Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: Color(0xFF0F172A),
                      ),
                      label: const Text('Modifica'),
                      backgroundColor: Colors.grey.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (ctx) =>
                              ManageCategoriesSheet(initialType: _type),
                        );
                      },
                    );
                  }

                  final cat = categories[index];
                  final isSelected = cat.name == _selectedCategory;
                  return ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    label: Text(cat.name),
                    selected: isSelected,
                    selectedColor: cat.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat.name);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Selettore Data
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Data: ${dateFormat.format(_selectedDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pulsante Salva
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: isExpense
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _isEditing
                    ? 'Salva Modifiche'
                    : (isExpense ? 'Aggiungi Spesa' : 'Aggiungi Entrata'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
