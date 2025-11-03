import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/fake_data.dart';
import 'package:pharmacy_app/models/category_model.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({super.key, required this.onTap});

  final Function(CategoryModel category) onTap;

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  final ValueNotifier<CategoryModel> _notifier = ValueNotifier(categories[0]);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _notifier,
      builder: (context, value, child) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories
                .map(
                  (e) => Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () {
                        widget.onTap.call(e);
                        _notifier.value = e;
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: radius16,
                          color: e.name == value.name
                              ? primaryColor
                              : Colors.transparent,
                        ),
                        padding: EdgeInsets.all(Gap.sm),
                        child: Column(
                          spacing: Gap.md,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SvgPicture.asset(
                              e.icon,
                              width: Gap.xl,
                              height: Gap.xl,
                              colorFilter: ColorFilter.mode(
                                e.name == value.name
                                    ? Colors.white
                                    : primaryColor,
                                BlendMode.srcIn,
                              ),
                            ),
                            Text(
                              e.name,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: e.name == value.name
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
