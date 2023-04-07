/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../playground_components.dart';
import '../assets/assets.gen.dart';

enum Rating { none, positive, negative }

class FeedbackWidget extends StatefulWidget {
  final String title;
  final Function(Rating) onRatingChanged;
  final Function(Rating, String) onSubmitPressed;

  const FeedbackWidget({
    required this.title,
    required this.onRatingChanged,
    required this.onSubmitPressed,
  });

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  Rating _rating = Rating.none;

  void _onRatingChanged(Rating rating) {
    setState(() {
      _rating = rating;
    });
    widget.onRatingChanged(_rating);

    final closeNotifier = PublicNotifier();
    showOverlay(
      context: context,
      closeNotifier: closeNotifier,
      positioned: Positioned(
        bottom: 50,
        left: 20,
        child: OverlayBody(
          child: _FeedbackDropdown(
            title: 'widgets.feedback.title'.tr(),
            subtitle: 'widgets.feedback.hint'.tr(),
            rating: _rating,
            onSubmitPressed: widget.onSubmitPressed,
            close: closeNotifier.notifyPublic,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(width: BeamSizes.size6),
        Tooltip(
          message: 'widgets.feedback.good'.tr(),
          child: InkWell(
            onTap: () {
              _onRatingChanged(Rating.positive);
            },
            child: _RatingIcon(
              groupValue: _rating,
              value: Rating.positive,
            ),
          ),
        ),
        const SizedBox(width: BeamSizes.size6),
        Tooltip(
          message: 'widgets.feedback.bad'.tr(),
          child: InkWell(
            onTap: () {
              _onRatingChanged(Rating.negative);
            },
            child: _RatingIcon(
              groupValue: _rating,
              value: Rating.negative,
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingIcon extends StatelessWidget {
  final Rating groupValue;
  final Rating value;
  const _RatingIcon({
    required this.groupValue,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final String asset;
    switch (value) {
      case Rating.positive:
        asset = isSelected ? Assets.svg.thumbUpFilled : Assets.svg.thumbUp;
        break;
      case Rating.negative:
        asset = isSelected ? Assets.svg.thumbDownFilled : Assets.svg.thumbDown;
        break;
      case Rating.none:
        asset = '';
        break;
    }
    return SvgPicture.asset(
      asset,
      package: PlaygroundComponents.packageName,
    );
  }
}

class _FeedbackDropdown extends StatelessWidget {
  final VoidCallback close;
  final Function(Rating, String) onSubmitPressed;
  final Rating rating;
  final String title;
  final String subtitle;

  _FeedbackDropdown({
    required this.title,
    required this.rating,
    required this.onSubmitPressed,
    required this.close,
    required this.subtitle,
  });

  final TextEditingController _feedback = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: BeamSizes.size8),
          Text(
            subtitle,
          ),
          const SizedBox(height: BeamSizes.size8),
          TextField(
            controller: _feedback,
            minLines: 3,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: BeamSizes.size8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  onSubmitPressed(rating, _feedback.text);
                  close();
                },
                child: const Text('widgets.feedback.send').tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
