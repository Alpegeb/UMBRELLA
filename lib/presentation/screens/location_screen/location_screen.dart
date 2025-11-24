import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

class CityData {
  final String name;
  final String subtitle;
  final String condition;
  final int temp;
  final int hi;
  final int lo;

  const CityData({
    required this.name,
    required this.subtitle,
    required this.condition,
    required this.temp,
    required this.hi,
    required this.lo,
  });
}

final _mockCities = [
  const CityData(name: "Istanbul", subtitle: "My Location • Home", condition: "Cloudy", temp: 15, hi: 19, lo: 15),
  const CityData(name: "Ankara", subtitle: "23:51", condition: "Mostly Cloudy", temp: 11, hi: 20, lo: 6),
  const CityData(name: "Marmaris", subtitle: "23:51", condition: "Partly Cloudy", temp: 18, hi: 25, lo: 15),
  const CityData(name: "Türkbükü", subtitle: "23:51", condition: "Mostly Cloudy", temp: 18, hi: 24, lo: 16),
  const CityData(name: "Midilli", subtitle: "22:51", condition: "Cloudy", temp: 15, hi: 19, lo: 13),
];

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key, required this.theme});

  final AppTheme theme;

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  List<CityData> get _filteredCities {
    if (_query.trim().isEmpty) return _mockCities;
    final q = _query.toLowerCase();
    return _mockCities.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.subtitle.toLowerCase().contains(q) ||
          c.condition.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
        child: Column(
          children: [
            _TopBar(theme: theme),
            const SizedBox(height: 16),
            _SearchBar(
              theme: theme,
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _filteredCities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _CityCard(
                  theme: theme,
                  city: _filteredCities[i],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new, color: theme.text),
        ),
        const SizedBox(width: 12),
        Text(
          "Locations",
          style: TextStyle(
            color: theme.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
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
    required this.onChanged,
  });

  final AppTheme theme;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

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
              onChanged: onChanged,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                hintText: "Search for a city or airport",
                hintStyle: TextStyle(color: theme.sub),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({required this.theme, required this.city});
  final AppTheme theme;
  final CityData city;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    city.subtitle,
                    style: TextStyle(color: theme.sub),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                "${city.temp}°",
                style: TextStyle(
                  color: theme.text,
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(city.condition, style: TextStyle(color: theme.text)),
              const Spacer(),
              Text(
                "H:${city.hi}° L:${city.lo}°",
                style: TextStyle(color: theme.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}