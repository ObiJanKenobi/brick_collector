import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CollectModal extends StatefulWidget {
  final CollectablePart part;

  const CollectModal(this.part, {super.key});

  @override
  State<StatefulWidget> createState() => CollectModalState();
}

class CollectModalState extends State<CollectModal> {
  CollectablePart get part => widget.part;

  TextEditingController inputController = TextEditingController();

  int currentCount = 0;

  CollectModalState();

  @override
  void initState() {
    super.initState();
    currentCount = part.collectedCount;
    updateInput();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextFormField(
            decoration: InputDecoration(
                label: const Text("Collected parts"), suffixIcon: IconButton(onPressed: collectAll, icon: const Icon(Icons.archive))),
            controller: inputController,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: saveInput,
            // initialValue: (part.collectedCount ?? 0).toString(),
          ),
          const SizedBox(width: 0, height: 10),
          Row(
            children: [
              const Spacer(),
              FilledButton.icon(
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll<Color>(AppColors.highlightColor.withValues(alpha: 0.8))),
                onPressed: decreaseCount,
                icon: const Icon(Icons.remove, size: 50),
                label: const Text("Reduce"),
              ),
              const SizedBox(width: 10, height: 0),
              FilledButton.icon(
                style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll<Color>(Colors.green)),
                onPressed: increaseCount,
                icon: const Icon(Icons.add, size: 50),
                label: const Text("Add"),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(width: 0, height: 10),
          FilledButton(
            style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll<Color>(AppColors.highlightColor)),
            onPressed: closeModal,
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void decreaseCount() {
    if (currentCount > 0) {
      setState(() {
        currentCount -= 1;
        updateInput();
      });
    }
  }

  void increaseCount() {
    if (currentCount < part.quantity) {
      setState(() {
        currentCount += 1;
        updateInput();
      });
    }
  }

  void saveInput(String? newValue) {
    if (newValue == null || newValue == "") return;
    setState(() {
      currentCount = int.tryParse(newValue) ?? 0;
    });
  }

  void closeModal() {
    part.collectedCount = currentCount;
    Navigator.of(context).pop(true);
  }

  void updateInput() {
    inputController.text = "$currentCount";
  }

  void collectAll() {
    setState(() {
      currentCount = part.quantity;
      updateInput();
    });
  }
}
