import 'dart:io';

import 'package:inventorio2/models/inv_product.dart';

class InvProductBuilder {
  String code;
  String name;
  String brand;
  String variant;
  String imageUrl;
  String heroCode;
  File imageFile;
  bool unset;

  static fromProduct(InvProduct product, String heroCode) {
    InvProductBuilder invProductBuilder = InvProductBuilder();
    invProductBuilder
        ..code = product.code
        ..name = product.name
        ..brand = product.brand
        ..variant = product.variant
        ..imageUrl = product.imageUrl
        ..unset = product.unset
        ..heroCode = heroCode;
    return invProductBuilder;
  }

  InvProduct build() {
    if (this.name == null || this.name.isEmpty) {
      return InvProduct.unset(code: this.code);
    }

    return InvProduct(
      code: this.code,
      name: this.name?.trim(),
      brand: this.brand?.trim(),
      variant: this.variant?.trim(),
      imageUrl: this.imageUrl
    );
  }

  @override
  String toString() {
    return {
      'code': this.code,
      'name': this.name,
      'brand': this.brand,
      'variant': this.variant,
      'imageUrl': this.imageUrl,
      'imageFile': this.imageFile?.path,
      'unset': this.unset,
      'heroCode': this.heroCode
    }.toString();
  }
}