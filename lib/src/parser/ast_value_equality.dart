part of 'ast.dart';

const _valueEquality = DeepCollectionEquality();

mixin _AstValueEquality {
  List<Object?> get equalityFields;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is _AstValueEquality &&
          _valueEquality.equals(equalityFields, other.equalityFields);

  @override
  int get hashCode => Object.hash(runtimeType, _valueEquality.hash(equalityFields));
}
