import 'package:flutter/material.dart';

class CCTVScreen extends StatefulWidget {
  const CCTVScreen({super.key});

  @override
  State<CCTVScreen> createState() => _CCTVScreenState();
}

class _CCTVScreenState extends State<CCTVScreen> {
  final List<Map<String, dynamic>> _cameras = [
    {
      'id': 'cam1',
      'name': 'Front Door',
      'status': 'Online',
      'thumbnail': 'assets/camera1.jpg',
    },
    {
      'id': 'cam2',
      'name': 'Back Yard',
      'status': 'Online',
      'thumbnail': 'assets/camera2.jpg',
    },
    {
      'id': 'cam3',
      'name': 'Garage',
      'status': 'Offline',
      'thumbnail': 'assets/camera3.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CCTV Monitoring')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Connected Cameras',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _cameras.length,
              itemBuilder: (context, index) {
                final camera = _cameras[index];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            image: DecorationImage(
                              image: AssetImage(camera['thumbnail']),
                              fit: BoxFit.cover,
                              colorFilter: camera['status'] == 'Offline'
                                  ? ColorFilter.mode(
                                      Colors.grey.withAlpha(
                                        (0.7 * 255).round(),
                                      ),
                                      BlendMode.saturation,
                                    )
                                  : null,
                            ),
                          ),
                          child: camera['status'] == 'Offline'
                              ? const Center(
                                  child: Text(
                                    'OFFLINE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              camera['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: camera['status'] == 'Online'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  camera['status'],
                                  style: TextStyle(
                                    color: camera['status'] == 'Online'
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
