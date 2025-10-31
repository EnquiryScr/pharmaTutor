import 'package:flutter/foundation.dart';

/// Base class for all ViewModels in the MVVM architecture
abstract class BaseViewModel with ChangeNotifier {
  // State management
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get hasError => _error != null;
  bool get hasSuccess => _successMessage != null;
  bool get isIdle => !_isLoading && !hasError && !hasSuccess;

  // State management methods
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void setError(String? error) {
    if (_error != error) {
      _error = error;
      if (error != null) {
        _successMessage = null; // Clear success message when error occurs
      }
      notifyListeners();
    }
  }

  void setSuccess(String? message) {
    if (_successMessage != message) {
      _successMessage = message;
      if (message != null) {
        _error = null; // Clear error when success occurs
      }
      notifyListeners();
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Initialize the ViewModel - called when the View is created
  @protected
  Future<void> init() async {
    // Override in child classes
  }

  /// Clean up resources - called when the View is disposed
  @protected
  void dispose() {
    // Clear all state
    _error = null;
    _successMessage = null;
    // Note: Don't call super.dispose() as ChangeNotifier.dispose() is final
  }

  /// Handle API errors consistently
  @protected
  void handleError(dynamic error, {String? customMessage}) {
    print('ViewModel Error: $error');
    String errorMessage = customMessage ?? 'An unexpected error occurred';
    
    if (error is String) {
      errorMessage = error;
    } else if (error is Exception) {
      errorMessage = error.toString();
    }
    
    setError(errorMessage);
  }

  /// Handle API success responses
  @protected
  void handleSuccess(dynamic data, {String? customMessage}) {
    String successMessage = customMessage ?? 'Operation completed successfully';
    
    if (data is String) {
      successMessage = data;
    }
    
    setSuccess(successMessage);
  }

  /// Execute an async operation with automatic loading and error handling
  @protected
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        setLoading(true);
      }
      
      final result = await operation();
      
      if (successMessage != null) {
        handleSuccess(result, customMessage: successMessage);
      }
      
      return result;
    } catch (error) {
      handleError(error, customMessage: errorMessage);
      return null;
    } finally {
      if (showLoading) {
        setLoading(false);
      }
    }
  }
}

/// Base class for ViewModels that handle specific types of data
abstract class BaseViewModel<T> extends BaseViewModel {
  // Data state
  T? _data;
  List<T>? _dataList;
  bool _hasData = false;

  // Getters
  T? get data => _data;
  List<T>? get dataList => _dataList;
  bool get hasData => _hasData;
  bool get isEmpty => !_hasData;
  int get dataCount => _dataList?.length ?? (_data != null ? 1 : 0);

  // Data management methods
  void setData(T? data) {
    _data = data;
    _hasData = data != null;
    notifyListeners();
  }

  void setDataList(List<T>? dataList) {
    _dataList = dataList;
    _hasData = dataList?.isNotEmpty == true;
    notifyListeners();
  }

  void addData(T item) {
    _dataList ??= [];
    _dataList!.add(item);
    _hasData = true;
    notifyListeners();
  }

  void updateData(T item, {int? index}) {
    if (index != null && _dataList != null && index < _dataList!.length) {
      _dataList![index] = item;
    } else if (_data == item) {
      _data = item;
    }
    notifyListeners();
  }

  void removeData(T item) {
    _dataList?.remove(item);
    if (_data == item) {
      _data = null;
      _hasData = false;
    } else {
      _hasData = _dataList?.isNotEmpty == true;
    }
    notifyListeners();
  }

  void clearData() {
    _data = null;
    _dataList = null;
    _hasData = false;
    notifyListeners();
  }

  /// Filter data list based on a condition
  @protected
  List<T> filterDataList(bool Function(T) condition) {
    return _dataList?.where(condition).toList() ?? [];
  }

  /// Sort data list based on a comparator
  @protected
  void sortDataList(int Function(T, T) compare) {
    if (_dataList != null) {
      _dataList!.sort(compare);
      notifyListeners();
    }
  }

  /// Search data list based on a query
  @protected
  List<T> searchDataList(String query, String Function(T) toString) {
    if (query.isEmpty) return _dataList ?? [];
    
    return _dataList?.where((item) => 
      toString(item).toLowerCase().contains(query.toLowerCase())
    ).toList() ?? [];
  }
}

/// Mixin for ViewModels that need refresh functionality
mixin RefreshableViewModel on BaseViewModel {
  bool _isRefreshing = false;

  bool get isRefreshing => _isRefreshing;

  /// Refresh the ViewModel data
  @protected
  Future<void> refresh() async {
    try {
      _isRefreshing = true;
      notifyListeners();
      
      await onRefresh();
    } catch (error) {
      handleError(error);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Override this method to implement refresh logic
  @protected
  Future<void> onRefresh() async {
    // Override in child classes
  }
}

/// Mixin for ViewModels that need pagination functionality
mixin PaginatedViewModel on BaseViewModel {
  bool _hasMoreData = true;
  int _currentPage = 0;
  static const int _pageSize = 20;

  bool get hasMoreData => _hasMoreData;
  int get currentPage => _currentPage;
  bool get isLoadingMore => _isLoading;

  /// Load more data for pagination
  @protected
  Future<bool> loadMore() async {
    if (!_hasMoreData || _isLoading) {
      return false;
    }

    final result = await executeAsync(
      () => onLoadMore(_currentPage + 1),
      showLoading: false,
    );

    if (result != null) {
      _currentPage++;
      _hasMoreData = result;
      return result;
    }

    return false;
  }

  /// Reset pagination state
  @protected
  void resetPagination() {
    _currentPage = 0;
    _hasMoreData = true;
  }

  /// Override this method to implement load more logic
  /// Return true if there are more items, false otherwise
  @protected
  Future<bool> onLoadMore(int page) async {
    // Override in child classes
    return false;
  }

  static int get pageSize => _pageSize;
}