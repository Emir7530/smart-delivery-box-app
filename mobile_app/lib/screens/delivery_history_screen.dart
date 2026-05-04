part of '../app.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: 'Delivery History',
              height: 66,
              topPadding: 5,
              bottomPadding: 7,
              iconSize: 24,
              titleFontSize: 20,
              trailing: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded),
                color: Colors.white,
                iconSize: 23,
                tooltip: 'Filter',
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = _clampDouble(
                    constraints.maxWidth * 0.06,
                    18,
                    32,
                  );
                  final verticalPadding = _clampDouble(
                    constraints.maxHeight * 0.04,
                    20,
                    32,
                  );
                  final separator = _clampDouble(
                    constraints.maxWidth * 0.045,
                    12,
                    18,
                  );

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      verticalPadding + 8,
                    ),
                    itemBuilder: (context, index) {
                      final item = model.deliveries[index];
                      return DeliveryCard(
                        delivery: item,
                        onTap: () => openScreen(
                          context,
                          DeliveryDetailsScreen(delivery: item),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        SizedBox(height: separator),
                    itemCount: model.deliveries.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
