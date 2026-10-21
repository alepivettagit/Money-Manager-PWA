import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/account_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/gemini_receipt_service.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/create_account_dialog.dart';

enum FilterPeriod { all, thisMonth, thisWeek, today }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FilterPeriod _selectedPeriod = FilterPeriod.thisMonth;

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    return transactions.where((tx) {
      switch (_selectedPeriod) {
        case FilterPeriod.all:
          return true;
        case FilterPeriod.thisMonth:
          return tx.date.year == now.year && tx.date.month == now.month;
        case FilterPeriod.thisWeek:
          final diff = now.difference(tx.date).inDays;
          return diff >= 0 && diff < 7;
        case FilterPeriod.today:
          return tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day;
      }
    }).toList();
  }

  void _showAccountSwitcherSheet(BuildContext context) {
    final accountProvider = context.read<AccountProvider>();
    final accounts = accountProvider.accounts;
    final currentAccount = accountProvider.selectedAccount;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 16),
              const Text(
                'Cambia Saldo / Conto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...accounts.map((acc) {
                final isSelected = acc.id == currentAccount?.id;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: isSelected
                      ? const Color(0xFF0F172A).withValues(alpha: 0.06)
                      : Colors.transparent,
                  leading: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: isSelected ? const Color(0xFF0F172A) : Colors.grey,
                  ),
                  title: Text(
                    acc.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                        )
                      : null,
                  onTap: () {
                    accountProvider.selectAccount(acc);
                    context.read<TransactionProvider>().loadTransactions(
                      acc.id,
                    );
                    Navigator.of(ctx).pop();
                  },
                );
              }),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context)
                            .pop(); // Torna a AccountSelectionScreen
                      },
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      label: const Text('Tutti i Saldi'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => CreateAccountDialog(
                            onCreated: (name, initialBalance) async {
                              final newAccount = await context
                                  .read<AccountProvider>()
                                  .createAccount(name, initialBalance);
                              if (context.mounted) {
                                context.read<AccountProvider>().selectAccount(
                                  newAccount,
                                );
                                context
                                    .read<TransactionProvider>()
                                    .loadTransactions(newAccount.id);
                              }
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nuovo Saldo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _openAddTransactionModal(Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddTransactionSheet(
        accountId: account.id,
        onAdd: (tx) {
          context.read<TransactionProvider>().addTransaction(tx);
        },
      ),
    );
  }

  Future<void> _openScanReceiptModal(Account account) async {
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
                'Scansiona Scontrino con IA',
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

    if (source == null || !mounted) return;

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

    // Mostra popup di attesa analisi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => const Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF10B981)),
                SizedBox(height: 18),
                Text(
                  'Gemini sta leggendo lo scontrino... 🧾',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 6),
                Text(
                  'Estrazione importo, negozio e prodotti',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final bytes = await photo.readAsBytes();
      final mimeType = photo.mimeType ?? 'image/jpeg';
      final result = await GeminiReceiptService.instance.analyzeReceipt(
        imageBytes: bytes,
        mimeType: mimeType,
        customCategories: customCategories,
      );

      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // Chiudi popup caricamento

      // Apri foglio transazione già pre-compilato
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => AddTransactionSheet(
          accountId: account.id,
          initialAmount: result.total,
          initialTitle: result.merchant,
          initialCategory: result.category,
          initialDate: result.date,
          initialNote: result.itemsSummary,
          initialType: TransactionType.expense,
          onAdd: (tx) {
            context.read<TransactionProvider>().addTransaction(tx);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // Chiudi popup caricamento
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore: ${e.toString().replaceAll("Exception: ", "")}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _openEditTransactionModal(Account account, Transaction tx) {
    final txProvider = context.read<TransactionProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddTransactionSheet(
        accountId: account.id,
        transactionToEdit: tx,
        onUpdate: (updatedTx) {
          txProvider.updateTransaction(updatedTx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updatedTx.title} aggiornata'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        },
        onDelete: () {
          txProvider.deleteTransaction(tx.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tx.title} eliminata'),
              action: SnackBarAction(
                label: 'Annulla',
                textColor: const Color(0xFF10B981),
                onPressed: () {
                  txProvider.addTransaction(tx);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final account = accountProvider.selectedAccount;

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: Text('Nessun conto selezionato')),
      );
    }

    // Calcolo saldo corrente
    final currentBalance = accountProvider.calculateCurrentBalance(
      account,
      txProvider.transactions,
    );

    final filteredList = _filterTransactions(txProvider.transactions);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Torna ai saldi',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showAccountSwitcherSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    account.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Cambia Saldo',
            onPressed: () => _showAccountSwitcherSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => txProvider.loadTransactions(account.id),
        child: CustomScrollView(
          slivers: [
            // Card Saldo Attuale
            SliverToBoxAdapter(
              child: SummaryCard(
                account: account,
                currentBalance: currentBalance,
              ),
            ),

            // Filtro Periodo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodChip(FilterPeriod.thisMonth, 'Questo Mese'),
                      const SizedBox(width: 8),
                      _buildPeriodChip(
                        FilterPeriod.thisWeek,
                        'Questa Settimana',
                      ),
                      const SizedBox(width: 8),
                      _buildPeriodChip(FilterPeriod.today, 'Oggi'),
                      const SizedBox(width: 8),
                      _buildPeriodChip(FilterPeriod.all, 'Tutto'),
                    ],
                  ),
                ),
              ),
            ),

            // Titolo Sezione Movimenti
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Movimenti Recenti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${filteredList.length} transazioni',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista Movimenti o Stato Vuoto
            if (filteredList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nessun movimento in questo periodo',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tocca "+ Nuova Spesa" per registrarne una',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final tx = filteredList[index];
                  return TransactionTile(
                    transaction: tx,
                    onTap: () => _openEditTransactionModal(account, tx),
                    onDelete: () {
                      txProvider.deleteTransaction(tx.id);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${tx.title} eliminata'),
                          action: SnackBarAction(
                            label: 'Annulla',
                            textColor: const Color(0xFF10B981),
                            onPressed: () {
                              txProvider.addTransaction(tx);
                            },
                          ),
                        ),
                      );
                    },
                  );
                }, childCount: filteredList.length),
              ),

            // Spazio in fondo per non coprire il Floating Action Button
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'scanReceiptFab',
            onPressed: () => _openScanReceiptModal(account),
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.document_scanner_rounded),
            label: const Text(
              'Scansiona',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          FloatingActionButton.extended(
            heroTag: 'newTxFab',
            onPressed: () => _openAddTransactionModal(account),
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Nuova Spesa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(FilterPeriod period, String label) {
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF0F172A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = period);
        }
      },
    );
  }
}
