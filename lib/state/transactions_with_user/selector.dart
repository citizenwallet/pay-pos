import 'package:pay_pos/models/transaction.dart';
import 'package:pay_pos/state/transactions_with_user/transactions_with_user.dart';

List<Transaction> selectUserTransactions(TransactionsWithUserState state) {
  final mergedTransactions = [
    ...state.sendingQueue,
    ...state.newTransactions,
    ...state.transactions
  ];

  return mergedTransactions;
}
