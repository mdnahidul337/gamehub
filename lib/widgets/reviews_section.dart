import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/review.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';

class ReviewsSection extends StatefulWidget {
  final String modId;

  const ReviewsSection({super.key, required this.modId});

  @override
  _ReviewsSectionState createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  final _reviewController = TextEditingController();
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DBService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (auth.currentUser != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _reviewController,
                    decoration: const InputDecoration(
                      labelText: 'Write a review',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Rating:'),
                      Expanded(
                        child: Slider(
                          value: _rating,
                          onChanged: (newRating) {
                            setState(() {
                              _rating = newRating;
                            });
                          },
                          divisions: 5,
                          label: _rating.toString(),
                          min: 0,
                          max: 5,
                        ),
                      ),
                      Text(_rating.toStringAsFixed(1)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_reviewController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please write a review')),
                        );
                        return;
                      }

                      final review = Review(
                        id: '', // Firestore will generate this
                        userId: auth.currentUser!.uid,
                        username: auth.currentUser!.username,
                        text: _reviewController.text,
                        rating: _rating,
                        createdAt: DateTime.now().millisecondsSinceEpoch,
                      );

                      await db.addReview(widget.modId, review);
                      _reviewController.clear();
                      setState(() {
                        _rating = 0;
                      });
                    },
                    child: const Text('Submit Review'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        StreamBuilder(
          stream: db.streamReviews(widget.modId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const Text('No reviews yet.');
            }

            final reviewsMap = snapshot.data!.snapshot.value as Map;
            final reviews = <Review>[];
            reviewsMap.forEach((key, value) {
              reviews.add(Review.fromMap(key, Map<String, dynamic>.from(value)));
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(review.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('${review.rating.toStringAsFixed(1)} ★'),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(review.text),
                        // Reply functionality can be added here
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
