import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import '../utils/base_viewmodel.dart';

/// Base class for all Views (Pages) in the MVVM architecture
abstract class BaseView<T extends BaseViewModel> extends ConsumerStatefulWidget {
  const BaseView({super.key});

  @override
  BaseViewState<T> createState() => BaseViewState<T>();
}

/// Base state class for Views that automatically manages ViewModel lifecycle
abstract class BaseViewState<T extends BaseViewModel> extends ConsumerState<BaseView<T>> {
  late T _viewModel;

  T get viewModel => _viewModel;

  /// Override this method to return the ViewModel instance
  /// This should use Provider/Riverpod to create the ViewModel
  @protected
  T createViewModel();

  /// Override this method to build the UI
  /// Return the widget tree for this view
  @protected
  Widget buildView(BuildContext context);

  /// Override this method to initialize data when the view is created
  @protected
  Future<void> initView() async {
    await viewModel.init();
  }

  /// Override this method to handle view lifecycle events
  @protected
  void handleLifecycleEvent(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        onPaused();
        break;
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.detached:
        onDetached();
        break;
      case AppLifecycleState.inactive:
        onInactive();
        break;
    }
  }

  /// Called when the app is paused
  @protected
  void onPaused() {}

  /// Called when the app is resumed
  @protected
  void onResumed() {}

  /// Called when the app is detached
  @protected
  void onDetached() {}

  /// Called when the app becomes inactive
  @protected
  void onInactive() {}

  /// Override this method to customize the scaffold wrapper
  @protected
  Widget buildScaffold(BuildContext context, Widget child) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(context, child),
      floatingActionButton: buildFloatingActionButton(context),
      bottomNavigationBar: buildBottomNavigationBar(context),
      drawer: buildDrawer(context),
      endDrawer: buildEndDrawer(context),
    );
  }

  /// Override this method to build a custom AppBar
  /// Return null for no AppBar
  @protected
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return null;
  }

  /// Override this method to build the main body content
  @protected
  Widget buildBody(BuildContext context, Widget child) {
    return child;
  }

  /// Override this method to build a custom Floating Action Button
  /// Return null for no FAB
  @protected
  Widget? buildFloatingActionButton(BuildContext context) {
    return null;
  }

  /// Override this method to build a custom Bottom Navigation Bar
  /// Return null for no bottom navigation
  @protected
  Widget? buildBottomNavigationBar(BuildContext context) {
    return null;
  }

  /// Override this method to build a custom Drawer
  /// Return null for no drawer
  @protected
  Widget? buildDrawer(BuildContext context) {
    return null;
  }

  /// Override this method to build a custom End Drawer
  /// Return null for no end drawer
  @protected
  Widget? buildEndDrawer(BuildContext context) {
    return null;
  }

  /// Show a loading overlay
  void showLoading({String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }

  /// Hide the loading overlay
  void hideLoading() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  /// Show an error dialog
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a success dialog
  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog
  Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    _viewModel = createViewModel();
    WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
  }

  @override
  void dispose() {
    _viewModel.dispose();
    WidgetsBinding.instance.removeObserver(_LifecycleObserver(this));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<T>(
        builder: (context, viewModel, child) {
          return buildScaffold(
            context,
            buildView(context),
          );
        },
      ),
    );
  }
}

/// Observer to handle app lifecycle events
class _LifecycleObserver extends WidgetsBindingObserver {
  final BaseViewState _viewState;

  _LifecycleObserver(this._viewState);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _viewState.handleLifecycleEvent(state);
  }
}

/// Mixin for views that need keyboard handling
mixin KeyboardMixin on BaseViewState {
  final _focusNode = FocusNode();
  
  FocusNode get focusNode => _focusNode;

  /// Call this method to hide keyboard
  void hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  /// Call this method to show keyboard
  void showKeyboard() {
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}

/// Mixin for views that need refresh functionality
mixin RefreshableMixin on BaseViewState {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  GlobalKey<RefreshIndicatorState> get refreshIndicatorKey => _refreshIndicatorKey;

  /// Implement pull-to-refresh logic
  @protected
  Future<void> onRefresh() async {
    await viewModel.refresh();
  }

  /// Wrap your content with RefreshIndicator
  Widget buildRefreshableContent(Widget child) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: onRefresh,
      child: child,
    );
  }
}

/// Mixin for views that need scroll handling
mixin ScrollableMixin on BaseViewState {
  final _scrollController = ScrollController();
  
  ScrollController get scrollController => _scrollController;

  /// Scroll to top of the list
  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Scroll to bottom of the list
  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Check if scrolled to bottom
  bool isScrolledToBottom() {
    return _scrollController.position.pixels >= 
           _scrollController.position.maxScrollExtent - 100;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}