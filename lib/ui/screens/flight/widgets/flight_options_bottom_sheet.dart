import 'package:flutter/material.dart';
import 'package:flymap/entity/flight.dart';

class FlightOptionsBottomSheet extends StatelessWidget {
  const FlightOptionsBottomSheet(this.flight, this.onDelete, {super.key});

  final Flight flight;
  final VoidCallback onDelete;

  static void showDeleteOptions(
    BuildContext context,
    Flight flight,
    VoidCallback onDelete,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FlightOptionsBottomSheet(flight, onDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Flight Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),

          // Delete option
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete Flight',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Remove this flight from your history'),
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              _showDeleteConfirmation(context, () {
                onDelete();
              });
            },
          ),

          // Cancel option
          ListTile(
            leading: const Icon(Icons.close, color: Colors.grey),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flight'),
        content: Text(
          'Are you sure you want to delete this flight (${flight.departure.displayCode}-${flight.arrival.displayCode})? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Delete the flight and navigate to home
  Future<void> _deleteFlight(BuildContext context) async {
    try {} catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting flight: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
