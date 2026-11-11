import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/report_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/report.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/priority_badge.dart';
import '../../shared/widgets/empty_state.dart';
import '../report_details/report_details_screen.dart';
import 'widgets/report_filter_sheet.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Report> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  final ReportFilterCriteria _filters = ReportFilterCriteria();

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ReportApiService.listReports(
        status: _filters.status,
        priority: _filters.priority,
        wilayaCode: _filters.wilayaCode,
        search: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _reports = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportFilterSheet(
        initialFilters: _filters,
        onApply: (newFilters) {
          setState(() {
            _filters.status = newFilters.status;
            _filters.priority = newFilters.priority;
            _filters.wilayaCode = newFilters.wilayaCode;
            _filters.wilayaName = newFilters.wilayaName;
          });
          _fetchReports();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Leak Reports'),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list_rounded),
                if (_filters.hasActiveFilters)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppBranding.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter Reports',
            onPressed: _openFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _fetchReports(),
              decoration: InputDecoration(
                hintText: 'Search by ID, wilaya, or description...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchReports();
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Active filter pills
          if (_filters.hasActiveFilters)
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_filters.status != null)
                    _buildActiveFilterChip(
                      'Status: ${_filters.status}',
                      onDeleted: () {
                        setState(() => _filters.status = null);
                        _fetchReports();
                      },
                    ),
                  if (_filters.priority != null)
                    _buildActiveFilterChip(
                      'Priority: ${_filters.priority}',
                      onDeleted: () {
                        setState(() => _filters.priority = null);
                        _fetchReports();
                      },
                    ),
                  if (_filters.wilayaCode != null)
                    _buildActiveFilterChip(
                      'Wilaya: ${_filters.wilayaName ?? _filters.wilayaCode}',
                      onDeleted: () {
                        setState(() {
                          _filters.wilayaCode = null;
                          _filters.wilayaName = null;
                        });
                        _fetchReports();
                      },
                    ),
                ],
              ),
            ),

          // Report list body
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, {required VoidCallback onDeleted}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InputChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onDeleted,
        backgroundColor: AppBranding.lightWaterBlue,
        side: const BorderSide(color: AppBranding.cardBorder),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 40, color: AppBranding.statusUnderRepair),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchReports,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchReports,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyStateView(
                icon: Icons.water_drop_outlined,
                title: 'No leak reports found',
                description: _filters.hasActiveFilters ||
                        _searchController.text.isNotEmpty
                    ? 'No reports match your selected filters or search query.'
                    : 'There are currently no leak reports in the system.',
                buttonText: _filters.hasActiveFilters ? 'Clear Filters' : null,
                onAction: _filters.hasActiveFilters
                    ? () {
                        setState(() {
                          _filters.reset();
                          _searchController.clear();
                        });
                        _fetchReports();
                      }
                    : null,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReports,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppBranding.cardBorder, width: 1),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailsScreen(reportId: report.id),
            ),
          );
          // Refresh list on return in case status was updated
          _fetchReports();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ApiConstants.resolvePhotoUrl(report.photoUrl),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 72,
                    height: 72,
                    color: AppBranding.lightWaterBlue,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppBranding.secondaryText,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${AppFormatters.formatShortId(report.id)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: AppBranding.deepNavy,
                          ),
                        ),
                        Text(
                          AppFormatters.formatDate(report.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppBranding.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.wilayaName ?? "Wilaya Unspecified"} • ${report.communeName ?? "Commune"}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppBranding.deepNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (report.note != null && report.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        report.note!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppBranding.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusBadge(status: report.status, fontSize: 10),
                        const SizedBox(width: 6),
                        PriorityBadge(priority: report.priority, fontSize: 10),
                      ],
                    ),
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
