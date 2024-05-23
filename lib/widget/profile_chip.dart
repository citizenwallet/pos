import 'package:scanner/widget/profile_circle.dart';
import 'package:flutter/material.dart';

class ProfileChip extends StatelessWidget {
  final String? name;
  final String? username;
  final String? image;
  final String? address;
  final void Function()? onEdit;

  const ProfileChip({
    super.key,
    this.name,
    this.username,
    this.image,
    this.address,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.all(
          Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          image == null
              ? Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey,
                      width: 0,
                    ),
                  ),
                  child: Icon(Icons.credit_card),
                )
              : ProfileCircle(
                  size: 40,
                  imageUrl: image,
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name != null && name!.isNotEmpty
                      ? name ?? 'Anonymous Tag'
                      : 'Anonymous Tag',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 10),
                Text(
                  username != null ? '@$username' : address ?? '@unknown',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
            )
        ],
      ),
    );
  }
}
