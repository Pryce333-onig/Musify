import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:musify/main.dart' show logger;
import 'package:musify/services/common_services.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/io_service.dart';

Future<void> importLocalSong() async {
  try {
    // 1. Open the phone's file picker for audio files
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true, // Allows you to pick several songs at once
    );

    if (result == null) return; // User cancelled

    // 2. Loop through the picked files
    for (var file in result.files) {
      if (file.path == null) continue;

      // 3. Create a unique ID for the song
      final ytid = 'local_${DateTime.now().millisecondsSinceEpoch}';
      
      // 4. Get the destination path inside Musify's private folder
      final audioPath = FilePaths.getAudioPath(ytid);
      final audioFile = File(audioPath);

      // 5. Create the folder and copy the file
      await audioFile.parent.create(recursive: true);
      await File(file.path!).copy(audioPath);

      // 6. Create the song entry for the app's database
      final Map<String, dynamic> newSong = {
        'ytid': ytid,
        'title': file.name.replaceAll(RegExp(r'\.[^.]+$'), ''), // Cleans up the filename for the title
        'artist': 'Local File',
        'audioPath': audioPath,
        'artworkPath': FilePaths.getArtworkPath(ytid),
        'isOffline': true,
        'duration': 0, // Will be read by the player
      };

      // 7. Add it to your offline songs list and save to database
      final updatedList = List.from(userOfflineSongs.value);
      updatedList.add(newSong);
      userOfflineSongs.value = updatedList;

      await addOrUpdateData<List>(
        'userNoBackup',
        'offlineSongs',
        userOfflineSongs.value,
      );
    }
  } catch (e, stackTrace) {
    logger.log('Error importing local song', error: e, stackTrace: stackTrace);
  }
}
