import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../custom_widgets/custom_buttons.dart';
import '../custom_widgets/text_field.dart';
import '../data_processing/budget_handler.dart'
    if (dart.library.html) '../data_processing/budget_web_handler.dart';
// import '../data_processing/category_handler.dart';
import '../enum.dart';
import '../models/budget.dart';
// import '../models/category.dart' as cat;
import '../models/user.dart';
import '../notifiers/budget_notifier.dart';
import '../notifiers/text_field_valid_notifier.dart';
import 'common_center_dialog.dart';
import 'currency_and_data_format/currency_format.dart';
import 'currency_and_data_format/date_format.dart';
import 'responsive_layout.dart';

class BudgetsCenterDialog extends StatefulWidget {
  const BudgetsCenterDialog({
    required this.notifier,
    required this.validNotifier,
    required this.userInteraction,
    required this.userDetails,
    this.addButtonOnPressedEvent,
    this.selectedIndex = -1,
    this.isMobile = false,
    this.isAddExpense = false,
    super.key,
  });

  final void Function()? addButtonOnPressedEvent;
  final UserInteractions userInteraction;
  final UserDetails userDetails;
  final BudgetNotifier notifier;
  final TextButtonValidNotifier validNotifier;
  final int selectedIndex;
  final bool isMobile;
  final bool isAddExpense;

  @override
  State<BudgetsCenterDialog> createState() => _BudgetsCenterDialogState();
}

class _BudgetsCenterDialogState extends State<BudgetsCenterDialog> {
  late FocusNode _nameFocusNode;
  late FocusNode _typeFocusNode;
  late FocusNode _notesFocusNode;
  late FocusNode _amountFocusNode;
  late FocusNode _dateFocusNode;

  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _dateController;
  late TextEditingController _remarkController;
  late TextEditingController _amountController;
  late ValueNotifier<bool> _budgetFormIsValid;
  String? selectedValue;

  void _initializeTextFieldValues() {
    if (widget.selectedIndex != -1) {
      final Budget currentBudget =
          widget.notifier.visibleBudgets[widget.selectedIndex];
      widget.notifier.budgetTextFieldDetails = BudgetTextFieldDetails(
        name: currentBudget.name,
        remarks: currentBudget.notes ?? '',
        date: currentBudget.createdDate,
        amount: currentBudget.target,
      );
    } else {
      widget.notifier.budgetTextFieldDetails = BudgetTextFieldDetails(
        name: '',
        remarks: '',
        date: DateTime.now(),
        amount: 0,
      );
    }
  }

  Widget _addDialog() {
    return isMobile(context)
        ? _buildMobileContentDialog()
        : _buildBudgetAddCenterDialog();
  }

  Widget _buildDialogBox(BuildContext context) {
    return _buildContentDialog();
  }

  CustomTextField _buildBudgetTitleTextField({bool isEdit = false}) {
    final bool isMobileAddExpense = widget.isMobile && widget.isAddExpense;
    if ((isEdit || isMobileAddExpense) &&
        widget.selectedIndex > -1 &&
        widget.notifier.budgetTextFieldDetails != null) {
      _nameController.text = widget.notifier.budgetTextFieldDetails!.name;
    }
    return CustomTextField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      hintText: 'Title',
      readOnly: isMobileAddExpense,
      canRequestFocus: !isMobileAddExpense,
      onChanged: (String value) {
        widget.notifier.budgetTextFieldDetails!.name = value;
        final bool isValid = _validateBudgetForm();
        _budgetFormIsValid.value = isValid;
        widget.validNotifier.isTextButtonValid(isValid);
      },
    );
  }

  // Widget _buildCategoryDropdown({
  //   EdgeInsetsGeometry? expandedInsets,
  //   bool isEdit = false,
  // }) {
  //   final bool isMobileAddExpense = widget.isMobile && widget.isAddExpense;
  //   if ((isEdit || isMobileAddExpense) &&
  //       widget.selectedIndex > -1 &&
  //       widget.notifier.budgetTextFieldDetails != null) {
  //     _typeController.text = widget.notifier.budgetTextFieldDetails!.remarks;
  //   }
  //   return CustomDropdown(
  //     items: widget.userDetails.userProfile.categoryStrings,
  //     expandedInsets: expandedInsets,
  //     enable: !isMobileAddExpense,
  //     hintText: 'Category',
  //     controller: _typeController,
  //     focusNode: _typeFocusNode,
  //     onSelected: (String? value) {
  //       widget.notifier.budgetTextFieldDetails!.category = value ?? '';

  //       // setState(() {
  //       //   selectedValue = value;
  //       // });
  //       widget.validNotifier.isTextButtonValid(
  //         _nameController.text,
  //         _typeController.text,
  //         _amountController.text,
  //         _dateController.text,
  //       );
  //     },
  //     selectedValue: selectedValue,
  //   );
  // }

  CustomTextField _buildAmountTextField({bool isEdit = false}) {
    if (isEdit &&
        widget.selectedIndex > -1 &&
        widget.notifier.budgetTextFieldDetails != null) {
      _amountController.text =
          widget.notifier.budgetTextFieldDetails!.amount.toString();
    }
    return CustomTextField(
      controller: _amountController,
      hintText: 'Amount',
      focusNode: _amountFocusNode,
      onChanged: (String value) {
        if (value.isNotEmpty) {
          widget.notifier.budgetTextFieldDetails!.amount = parseCurrency(
            value,
            widget.userDetails.userProfile,
          );
          final bool isValid = _validateBudgetForm();
          _budgetFormIsValid.value = isValid;
          widget.validNotifier.isTextButtonValid(isValid);
        }
      },
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.singleLineFormatter,
        FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
      ],
    );
  }

  bool _validateBudgetForm() {
    if (widget.userInteraction == UserInteractions.edit) {
      final Budget currentBudget =
          widget.notifier.visibleBudgets[widget.selectedIndex];
      return _nameController.text != currentBudget.name ||
          _amountController.text != currentBudget.target.toString() ||
          _dateController.text != formatDate(currentBudget.createdDate) ||
          _remarkController.text != currentBudget.notes;
    }
    if (widget.isAddExpense) {
      return _amountController.text.isNotEmpty;
    }
    return _nameController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _dateController.text.isNotEmpty;
  }

  Widget _buildDateTextField({bool isEdit = false}) {
    final bool isMobileAddExpense = widget.isMobile && widget.isAddExpense;
    if ((isEdit || isMobileAddExpense) &&
        widget.selectedIndex > -1 &&
        widget.notifier.budgetTextFieldDetails != null) {
      _dateController.text = formatDate(
        widget.notifier.budgetTextFieldDetails!.date,
      );
    }
    return buildDateTextField(
      hintText: 'Date',
      focusNode: _dateFocusNode,
      dateController: _dateController,
      userDetails: widget.userDetails,
      context: context,
      onChanged: (String value) {
        widget.notifier.budgetTextFieldDetails!.date = DateFormat(
          widget.userDetails.userProfile.dateFormat,
        ).parse(value);
        final bool isValid = _validateBudgetForm();
        _budgetFormIsValid.value = isValid;
        widget.validNotifier.isTextButtonValid(isValid);
      },
    );
  }

  CustomTextField _buildNotesTextField({bool isEdit = false}) {
    final bool isMobileAddExpense = widget.isMobile && widget.isAddExpense;
    if ((isEdit || isMobileAddExpense) &&
        widget.selectedIndex > -1 &&
        widget.notifier.budgetTextFieldDetails != null) {
      _remarkController.text = widget.notifier.budgetTextFieldDetails!.remarks;
    }
    return CustomTextField(
      maxLines: 4,
      isRequired: false,
      controller: _remarkController,
      hintText: 'Notes',
      focusNode: _notesFocusNode,
      keyboardType: TextInputType.streetAddress,
      onChanged: (String value) {
        widget.notifier.budgetTextFieldDetails!.remarks = value;
        if (isEdit) {
          final bool isValid = _validateBudgetForm();
          _budgetFormIsValid.value = isValid;
          widget.validNotifier.isTextButtonValid(isValid);
        }
      },
      readOnly: isMobileAddExpense,
      canRequestFocus: !isMobileAddExpense,
    );
  }

  Widget _buildBudgetAddCenterDialog() {
    return CommonCenterDialog(
      dialogHeader:
          widget.userInteraction == UserInteractions.edit
              ? 'Edit Budget'
              : 'Create Budget',
      onCloseIconPressed: () {
        widget.validNotifier.isTextButtonValid(false);
        Navigator.pop(context);
      },
      content: _buildDialogBox(context),
      actions: <Widget>[
        ValueListenableBuilder<bool>(
          valueListenable: _budgetFormIsValid,
          builder: (context, isValid, child) {
            return CustomTextActionButtons(
              onCancelAction: () {
                widget.validNotifier.isTextButtonValid(false);
                Navigator.pop(context);
              },
              onAddOrEditAction:
                  isValid
                      ? () async {
                        final Budget budget = Budget(
                          name: _nameController.text,
                          target: parseCurrency(
                            _amountController.text,
                            widget.userDetails.userProfile,
                          ),
                          notes: _remarkController.text,
                          expense: 0,
                          createdDate: DateFormat(
                            widget.userDetails.userProfile.dateFormat,
                          ).parse(_dateController.text),
                        );
                        if (widget.userInteraction == UserInteractions.edit) {
                          final Budget currentBudget =
                              widget.notifier.visibleBudgets[widget
                                  .selectedIndex];
                          budget.expense = currentBudget.expense;
                          widget.notifier.editBudget(
                            currentBudget,
                            budget,
                            widget.selectedIndex,
                          );
                          updateBudgets(
                            context,
                            widget.userDetails,
                            budget,
                            widget.userInteraction,
                            index: widget.notifier.currentIndex,
                          );
                        } else {
                          if (widget.notifier.isFirstTime) {
                            widget.notifier.read(widget.userDetails);
                          }
                          widget.notifier.createBudget(budget);
                          updateBudgets(
                            context,
                            widget.userDetails,
                            budget,
                            widget.userInteraction,
                          );
                        }
                        widget.validNotifier.isTextButtonValid(false);
                        Navigator.pop(context);
                      }
                      : null,
              showEditButton: widget.userInteraction == UserInteractions.edit,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMobileContentDialog() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        spacing: 24.0,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: _buildBudgetTitleTextField(
              isEdit: widget.userInteraction == UserInteractions.edit,
            ),
          ),
          // _buildCategoryDropdown(
          //   expandedInsets: EdgeInsets.zero,
          //   isEdit: widget.userInteraction == UserInteractions.edit,
          // ),
          _buildAmountTextField(
            isEdit: widget.userInteraction == UserInteractions.edit,
          ),
          _buildDateTextField(
            isEdit: widget.userInteraction == UserInteractions.edit,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _buildNotesTextField(
              isEdit: widget.userInteraction == UserInteractions.edit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentDialog() {
    return Column(
      spacing: 24.0,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildFieldsAndDropdowns(
          _buildBudgetTitleTextField(
            isEdit: widget.userInteraction == UserInteractions.edit,
          ),
          // _buildCategoryDropdown(
          //   expandedInsets: EdgeInsets.zero,
          //   isEdit: widget.userInteraction == UserInteractions.edit,
          // ),
          _buildAmountTextField(
            isEdit: widget.userInteraction == UserInteractions.edit,
          ),
        ),
        _buildFieldsAndDropdowns(
          // _buildAmountTextField(
          //   isEdit: widget.userInteraction == UserInteractions.edit,
          // ),
          _buildDateTextField(
            isEdit: widget.userInteraction == UserInteractions.edit,
          ),
        ),
        _buildFieldsAndDropdowns(
          _buildNotesTextField(
            isEdit: widget.userInteraction == UserInteractions.edit,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldsAndDropdowns(Widget firstChild, [Widget? secondChild]) {
    return Row(
      spacing: 16.0,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: firstChild),
        if (secondChild != null) Expanded(child: secondChild),
      ],
    );
  }

  @override
  void initState() {
    _typeFocusNode = FocusNode();
    _dateFocusNode = FocusNode();
    _amountFocusNode = FocusNode();
    _nameFocusNode = FocusNode();
    _notesFocusNode = FocusNode();

    _nameController = TextEditingController();
    _typeController = TextEditingController();
    _dateController = TextEditingController();
    _remarkController = TextEditingController();
    _amountController = TextEditingController();
    _budgetFormIsValid = ValueNotifier<bool>(false);
    _nameController.addListener(_validateBudgetForm);
    _amountController.addListener(_validateBudgetForm);
    _dateController.addListener(_validateBudgetForm);
    _initializeTextFieldValues();

    super.initState();
  }

  @override
  void dispose() {
    _typeFocusNode.dispose();

    _notesFocusNode.dispose();
    _amountFocusNode.dispose();
    _typeController.dispose();

    _dateController.dispose();
    _remarkController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _addDialog();
  }
}
