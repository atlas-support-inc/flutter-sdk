import 'dart:math';

const appId = '7wukb9ywp9__x33kupocfb';
const user = {
  'id': '1e9322f7-fa86-400d-bf84-4cb64a981910',
  'hash': '5d88e73eeba85abf97aec8d390e9ab0e467bd7b212a2bcca1c3fbcaa8972ad01',
};

// const appId = 'a95uw0hfsr';
// const user = {
//   'id': '1e38bc05-b4ed-446e-a75a-c0f5051963f2',
//   'hash': '1a94a4a2cf6c727799ea3c2361724766391c5c9edfc611e4f84e01d9e9fc9f33',
// };

const userSecond = {
  'id': '15c4666c-2def-45a9-825c-590b3d4c95df',
  'hash': 'bbf35a628677552491b17695c85986400736cafcdd80457e3534c34881b7f0c4',
};

const userEmpty = {
  'id': '',
  'hash': '',
  'name': '',
  'email': '',
};

String _getRandomString(int length) {
  final random = Random();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

var userInvalid = {
  'id': _getRandomString(10),
  'hash': _getRandomString(10),
};
