import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../providers/settings_state.dart';
import '../../../providers/weather_state.dart';
import '../../../services/places_service.dart';
import '../../../services/weather_models.dart';
import '../../../services/weather_utils.dart';
import '../../../services/weather_units.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key, required this.theme});

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: LocationsView(
          theme: theme,
          showBackButton: true,
          onSelectIndex: (index) {
            context.read<WeatherState>().setActiveIndex(index);
            Navigator.of(context).maybePop();
          },
        ),
      ),
    );
  }
}

class LocationsView extends StatefulWidget {
  const LocationsView({
    super.key,
    required this.theme,
    required this.onSelectIndex,
    this.showBackButton = true,
    this.bottomInset = 0,
  });

  final AppTheme theme;
  final ValueChanged<int> onSelectIndex;
  final bool showBackButton;
  final double bottomInset;

  @override
  State<LocationsView> createState() => _LocationsViewState();
}

class _LocationsViewState extends State<LocationsView> {
  final TextEditingController _searchCtrl = TextEditingController();
  final PlacesService _places = PlacesService();
  Timer? _debounce;
  String _query = "";
  bool _searching = false;
  String? _searchError;
  String? _addingPlaceId;
  int _addRequestId = 0;
  List<PlaceSuggestion> _suggestions = [];
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  int _matchLocationIndex(
    WeatherState weather, {
    PlaceSuggestion? suggestion,
    PlaceDetails? details,
  }) {
    final placeId = details?.placeId ?? suggestion?.placeId;
    if (placeId != null) {
      final idx = weather.locations
          .indexWhere((loc) => loc.placeId == placeId);
      if (idx != -1) return idx;
    }

    if (details != null) {
      const threshold = 0.01;
      for (int i = 0; i < weather.locations.length; i++) {
        final loc = weather.locations[i];
        if ((loc.latitude - details.latitude).abs() < threshold &&
            (loc.longitude - details.longitude).abs() < threshold) {
          return i;
        }
      }
    }

    if (suggestion != null) {
      final name = suggestion.primaryText.trim().toLowerCase();
      final secondary = suggestion.secondaryText.trim().toLowerCase();
      for (int i = 0; i < weather.locations.length; i++) {
        final loc = weather.locations[i];
        if (loc.name.trim().toLowerCase() != name) continue;
        if (secondary.isEmpty) return i;
        if (loc.subtitle.trim().toLowerCase().contains(secondary)) return i;
      }
    }
    return -1;
  }

  List<int> _filteredIndices(WeatherState weather) {
    final q = _query.trim().toLowerCase();
    final indices = List<int>.generate(weather.locations.length, (i) => i);
    if (q.isEmpty) return indices;
    final filtered = indices.where((i) {
      final loc = weather.locations[i];
      final snap = weather.snapshotForIndex(i);
      return loc.name.toLowerCase().contains(q) ||
          loc.subtitle.toLowerCase().contains(q) ||
          snap.current.condition.toLowerCase().contains(q);
    }).toList();
    filtered.sort();
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final weather = context.watch<WeatherState>();
    final settings = context.watch<SettingsState>();
    final isOffline = weather.isOffline;
    final isEditing = settings.locationsEditing;
    final results = _filteredIndices(weather);
    final trimmedQuery = _query.trim();
    final hasQuery = trimmedQuery.isNotEmpty;
    final deviceLocation =
        weather.locations.isNotEmpty ? weather.locations.first : null;

    final List<Widget> items = [];
    void addItem(Widget widget) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 10));
      items.add(widget);
    }
    void addSectionHeader(String text) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 14));
      items.add(_SectionHeader(theme: theme, text: text));
      items.add(const SizedBox(height: 8));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          _TopBar(
            theme: theme,
            showBackButton: widget.showBackButton,
            isEditing: isEditing,
            onToggleEdit: _toggleEditing,
          ),
          const SizedBox(height: 16),
          _SearchBar(
            theme: theme,
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: (v) => _onQueryChanged(v, deviceLocation, isOffline),
            enabled: !isEditing && !isOffline,
          ),
          if (isOffline && !isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _StatusLine(
                theme: theme,
                text: 'Connect to the internet to search places.',
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: isEditing
                ? _buildEditList(weather, settings)
                : Builder(
                    builder: (context) {
                      if (results.isEmpty && !hasQuery) {
                        return Center(
                          child: Text(
                            "No locations available.",
                            style: TextStyle(
                              color: theme.sub,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (results.isNotEmpty) {
                        addSectionHeader('Saved Locations');
                        for (final index in results) {
                          final location = weather.locations[index];
                          final snapshot = weather.snapshotForIndex(index);
                          final errorMessage = weather.errorForIndex(index);
                          addItem(
                            _LocationCard(
                              theme: theme,
                              location: location,
                              snapshot: snapshot,
                              useCelsius: settings.useCelsius,
                              isActive: index == weather.activeIndex,
                              errorMessage: errorMessage,
                              showEditActions: false,
                              reorderIndex: null,
                              onRemove: null,
                              onTap: () => widget.onSelectIndex(index),
                            ),
                          );
                        }
                      }

                      if (hasQuery) {
                        addSectionHeader('Search Results');
                        if (isOffline) {
                          addItem(
                            _StatusLine(
                              theme: theme,
                              text:
                                  'Connect to the internet to search places.',
                            ),
                          );
                        } else if (_searching) {
                          addItem(
                            _StatusLine(
                              theme: theme,
                              text: 'Searching places...',
                            ),
                          );
                        } else if (_searchError != null) {
                          addItem(
                            _StatusLine(
                              theme: theme,
                              text: _searchError!,
                            ),
                          );
                        } else if (_suggestions.isEmpty) {
                          addItem(
                            _StatusLine(
                              theme: theme,
                              text: 'No places found for "$trimmedQuery".',
                            ),
                          );
                        } else {
                          for (final suggestion in _suggestions) {
                            final adding = _addingPlaceId == suggestion.placeId;
                            addItem(
                              _PlaceResultTile(
                                theme: theme,
                                suggestion: suggestion,
                                loading: adding,
                                onTap: adding
                                    ? null
                                    : () => _selectSuggestion(
                                          suggestion,
                                          context.read<WeatherState>(),
                                        ),
                              ),
                            );
                          }
                        }
                      }

                      return ListView(
                        padding: EdgeInsets.only(
                          bottom: 20 + widget.bottomInset,
                        ),
                        children: items,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _onQueryChanged(
    String value,
    WeatherLocation? deviceLocation,
    bool isOffline,
  ) {
    setState(() {
      _query = value;
      _searchError = null;
    });
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _searching = false;
        _suggestions = [];
      });
      return;
    }
    if (isOffline) {
      setState(() {
        _searching = false;
        _suggestions = [];
        _searchError = 'Connect to the internet to search places.';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchPlaces(trimmed, deviceLocation);
    });
  }

  void _toggleEditing() {
    final settings = context.read<SettingsState>();
    final next = !settings.locationsEditing;
    setState(() {
      if (next) {
        _searchCtrl.clear();
        _query = '';
        _searchError = null;
        _suggestions = [];
      }
    });
    settings.setLocationsEditing(next);
  }

  Future<void> _searchPlaces(
    String query,
    WeatherLocation? deviceLocation,
  ) async {
    if (!mounted) return;
    if (context.read<WeatherState>().isOffline) {
      setState(() {
        _searching = false;
        _searchError = 'Connect to the internet to search places.';
        _suggestions = [];
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await _places.autocomplete(
        query,
        latitude: deviceLocation?.latitude,
        longitude: deviceLocation?.longitude,
      );
      if (!mounted || _query.trim() != query) return;
      setState(() {
        _suggestions = results;
      });
    } catch (e) {
      if (!mounted || _query.trim() != query) return;
      final message = e is PlacesApiException
          ? e.message
          : 'Unable to search places.';
      setState(() {
        _searchError = message;
        _suggestions = [];
      });
    } finally {
      if (mounted && _query.trim() == query) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _selectSuggestion(
    PlaceSuggestion suggestion,
    WeatherState weather,
  ) async {
    if (_addingPlaceId != null) return;
    final existingIndex =
        _matchLocationIndex(weather, suggestion: suggestion);
    if (existingIndex != -1) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.clearSnackBars();
      widget.onSelectIndex(existingIndex);
      if (!mounted) return;
      _searchCtrl.clear();
      setState(() {
        _query = '';
        _suggestions = [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    final requestId = ++_addRequestId;
    setState(() => _addingPlaceId = suggestion.placeId);
    try {
      PlaceDetails details;
      try {
        details = await _places.fetchDetails(suggestion.placeId);
      } catch (e) {
        if (!mounted || requestId != _addRequestId) return;
        final existingIndex =
            _matchLocationIndex(weather, suggestion: suggestion);
        if (existingIndex != -1) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.clearSnackBars();
          widget.onSelectIndex(existingIndex);
          if (!mounted) return;
          _searchCtrl.clear();
          setState(() {
            _query = '';
            _suggestions = [];
            _searching = false;
            _searchError = null;
          });
          return;
        }
        final message = e is PlacesApiException
            ? e.message
            : 'Unable to add that location.';
        setState(() {
          _searchError = message;
          _searching = false;
        });
        return;
      }

      final location = WeatherLocation(
        name: details.name,
        subtitle: details.address ?? suggestion.secondaryText,
        latitude: details.latitude,
        longitude: details.longitude,
        placeId: details.placeId,
      );
      int index;
      try {
        index = await weather.addLocation(location);
      } catch (e) {
        if (!mounted || requestId != _addRequestId) return;
        final existingIndex = _matchLocationIndex(
          weather,
          suggestion: suggestion,
          details: details,
        );
        if (existingIndex != -1) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.clearSnackBars();
          widget.onSelectIndex(existingIndex);
          _searchCtrl.clear();
          setState(() {
            _query = '';
            _suggestions = [];
            _searching = false;
          });
          return;
        }
        final message = e is PlacesApiException
            ? e.message
            : 'Unable to add that location.';
        setState(() {
          _searchError = message;
          _searching = false;
        });
        return;
      }
      if (!mounted || requestId != _addRequestId) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.clearSnackBars();
      widget.onSelectIndex(index);
      if (!mounted) return;
      _searchCtrl.clear();
      setState(() {
        _query = '';
        _suggestions = [];
        _searching = false;
        _searchError = null;
      });
    } finally {
      if (mounted && requestId == _addRequestId) {
        setState(() => _addingPlaceId = null);
      }
    }
  }

  Future<bool> _confirmRemoveLocation(int index) async {
    if (!mounted) return false;
    final location = context.read<WeatherState>().locations[index];
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) {
        final theme = widget.theme;
        const danger = Color(0xFFE5484D);
        return Dialog(
          backgroundColor: theme.cardAlt,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: theme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
            color: danger.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_outline, color: danger),
                ),
                const SizedBox(height: 12),
                Text(
                  'Remove ${location.name}?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can add it back anytime from search.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.sub),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.border),
                          foregroundColor: theme.text,
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Keep'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: danger,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return confirmed == true && mounted;
  }

  Future<void> _removeLocation(int index) async {
    await context.read<WeatherState>().removeLocation(index);
  }

  Widget _buildEditList(WeatherState weather, SettingsState settings) {
    final theme = widget.theme;
    final locations = weather.locations;
    final savedCount = locations.isNotEmpty ? locations.length - 1 : 0;

    if (locations.isEmpty) {
      return Center(
        child: Text(
          "No locations available.",
          style: TextStyle(
            color: theme.sub,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final deviceLocation = locations.first;
    final deviceSnapshot = weather.snapshotForIndex(0);

    return Column(
      children: [
        _LocationCard(
          theme: theme,
          location: deviceLocation,
          snapshot: deviceSnapshot,
          useCelsius: settings.useCelsius,
          isActive: weather.activeIndex == 0,
          errorMessage: weather.errorForIndex(0),
          showEditActions: false,
          reorderIndex: null,
          onRemove: null,
          onTap: () => widget.onSelectIndex(0),
        ),
        const SizedBox(height: 10),
        if (savedCount == 0)
          Expanded(
            child: Center(
              child: Text(
                "No saved locations to edit.",
                style: TextStyle(
                  color: theme.sub,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Expanded(
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              proxyDecorator: (child, _, __) => Material(
                color: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: child,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              padding: EdgeInsets.only(
                bottom: widget.bottomInset,
              ),
              onReorder: (oldIndex, newIndex) =>
                  _reorderSaved(oldIndex, newIndex, weather),
              children: List.generate(savedCount, (i) {
                final index = i + 1;
                final location = locations[index];
                final snapshot = weather.snapshotForIndex(index);
                final itemKey =
                    ValueKey('${location.placeId ?? location.name}_$index');
                return KeyedSubtree(
                  key: itemKey,
            child: _SwipeToRemoveTile(
              key: itemKey,
              dismissKey: itemKey,
              theme: theme,
              onConfirmRemove: () => _confirmRemoveLocation(index),
              onRemove: () => _removeLocation(index),
                    child: Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                      child: _LocationCard(
                        theme: theme,
                        location: location,
                        snapshot: snapshot,
                        useCelsius: settings.useCelsius,
                        isActive: weather.activeIndex == index,
                        errorMessage: weather.errorForIndex(index),
                        showEditActions: true,
                        reorderIndex: i,
                        onRemove: null,
                        onTap: null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  void _reorderSaved(int oldIndex, int newIndex, WeatherState weather) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0) return;
    weather.moveLocation(oldIndex + 1, newIndex + 1);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.theme,
    required this.showBackButton,
    required this.isEditing,
    required this.onToggleEdit,
  });

  final AppTheme theme;
  final bool showBackButton;
  final bool isEditing;
  final VoidCallback onToggleEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBackButton)
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: theme.text),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        if (showBackButton) const SizedBox(width: 4),
        Text(
          "Locations",
          style: TextStyle(
            color: theme.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Tooltip(
          message: isEditing ? "Done" : "Edit",
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggleEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    color: isEditing ? theme.accent : theme.sub,
                    size: 20,
                  ),
                  if (isEditing) ...[
                    const SizedBox(width: 6),
                    Text(
                      "Done",
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.theme,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.enabled,
  });

  final AppTheme theme;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.sub),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onTap: () => focusNode.requestFocus(),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              enabled: enabled,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                hintText: "Search for a city or airport",
                hintStyle: TextStyle(color: theme.sub),
                border: InputBorder.none,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (!enabled || value.text.isEmpty) {
                return const SizedBox(width: 4);
              }
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                icon: Icon(Icons.close_rounded, color: theme.sub, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.theme, required this.text});

  final AppTheme theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: theme.sub,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.theme, required this.text});

  final AppTheme theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: theme.sub,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PlaceResultTile extends StatelessWidget {
  const _PlaceResultTile({
    required this.theme,
    required this.suggestion,
    required this.loading,
    required this.onTap,
  });

  final AppTheme theme;
  final PlaceSuggestion suggestion;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.place_outlined, color: theme.sub),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.primaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (suggestion.secondaryText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        suggestion.secondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.sub,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.accent,
                ),
              )
            else
              Icon(Icons.add_circle_outline, color: theme.accent),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.theme,
    required this.location,
    required this.snapshot,
    required this.useCelsius,
    required this.isActive,
    required this.errorMessage,
    required this.showEditActions,
    required this.reorderIndex,
    required this.onRemove,
    required this.onTap,
  });

  final AppTheme theme;
  final WeatherLocation location;
  final WeatherSnapshot snapshot;
  final bool useCelsius;
  final bool isActive;
  final String? errorMessage;
  final bool showEditActions;
  final int? reorderIndex;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final current = snapshot.current;
    final daily = snapshot.daily;
    final range = highLowForDate(daily, snapshot.hourly, DateTime.now());
    final temp = tempValue(current.tempC, useCelsius).round();
    final hasRange = range != null;
    final hi = range == null
        ? null
        : tempValue(range.highC, useCelsius).round();
    final lo = range == null
        ? null
        : tempValue(range.lowC, useCelsius).round();
    final subtitle = location.subtitle.isNotEmpty
        ? location.subtitle
        : (location.isDevice ? "My Location" : "Saved location");
    final condition = displayCondition(current.condition);
    final hasError = errorMessage != null && snapshot.isFallback;
    final showPlaceholder = snapshot.isFallback;
    final tempText = showPlaceholder ? "--" : "$temp°";
    final conditionText =
        showPlaceholder ? (hasError ? "Weather unavailable" : "--") : condition;
    final hiLoText =
        showPlaceholder || !hasRange ? "H:-- L:--" : "H:$hi° L:$lo°";

    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? theme.accent : theme.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showEditActions)
                    _EditActions(
                      theme: theme,
                      reorderIndex: reorderIndex,
                    ),
                  Text(
                    tempText,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  conditionText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: showPlaceholder ? theme.sub : theme.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                hiLoText,
                style: TextStyle(
                  color: showPlaceholder ? theme.sub : theme.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: content,
    );
  }
}

class _EditActions extends StatelessWidget {
  const _EditActions({
    required this.theme,
    required this.reorderIndex,
  });

  final AppTheme theme;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    if (reorderIndex == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReorderableDragStartListener(
          index: reorderIndex!,
          child: Container(
            width: 52,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.cardAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Icon(Icons.drag_indicator, color: theme.sub, size: 20),
          ),
        ),
      ],
    );
  }
}

class _SwipeToRemoveTile extends StatefulWidget {
  const _SwipeToRemoveTile({
    super.key,
    required this.dismissKey,
    required this.theme,
    required this.child,
    required this.onConfirmRemove,
    required this.onRemove,
  });

  final Key dismissKey;
  final AppTheme theme;
  final Widget child;
  final Future<bool> Function() onConfirmRemove;
  final VoidCallback onRemove;

  @override
  State<_SwipeToRemoveTile> createState() => _SwipeToRemoveTileState();
}

class _SwipeToRemoveTileState extends State<_SwipeToRemoveTile>
    with SingleTickerProviderStateMixin {
  static const double _maxSlide = 96;
  static const double _snapThreshold = 48;
  static const Duration _snapDuration = Duration(milliseconds: 180);

  late final AnimationController _controller;
  Animation<double>? _animation;
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _snapDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _controller.stop();
    final begin = _offset;
    _animation = Tween<double>(begin: begin, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() => _offset = _animation!.value);
      });
    _controller.forward(from: 0);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) _controller.stop();
    final delta = -details.delta.dx;
    if (delta == 0) return;
    setState(() {
      _offset = (_offset + delta).clamp(0, _maxSlide);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_offset >= _snapThreshold) {
      _animateTo(_maxSlide);
    } else {
      _animateTo(0);
    }
  }

  Future<void> _handleRemovePressed() async {
    if (_offset == 0) return;
    final confirmed = await widget.onConfirmRemove();
    if (!mounted) return;
    if (confirmed) {
      widget.onRemove();
    } else {
      _animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const removeColor = Color(0xFFE5484D);
    return Container(
      key: widget.dismissKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: removeColor,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 14),
              child: TextButton.icon(
                onPressed: _handleRemovePressed,
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                label: Text(
                  'Remove',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: () => _animateTo(0),
            behavior: HitTestBehavior.translucent,
            child: Transform.translate(
              offset: Offset(-_offset, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
