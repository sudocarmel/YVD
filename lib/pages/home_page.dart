import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'downloaded_page.dart';

class YoutubeDowloader extends StatefulWidget {
  const YoutubeDowloader({super.key});
  @override
  State<YoutubeDowloader> createState() => _YoutubeDowloaderState();
}

class _YoutubeDowloaderState extends State<YoutubeDowloader> {
  //etat de la recherche sur youtube
  double _progress = 0.0;
  bool _isDownloading = false;
  bool _videoFound = false;
  String error = "";
  Map<String, String> videoMeta = {
    "title": "",
    "author": "",
    "date": "",
    "description": "",
    "views": "",
    "thumbnail": "",
  };
  String _textStatus = "";
  //
  Future yd(String youtubeVideoLink) async {
    final yt = YoutubeExplode();
    setState(() {
      _progress = 0.0;
      _isDownloading = true;
      _textStatus = "Récupération des informations";
    });
    // Get the video metadata.
    try {
      final videoMetaData = await yt.videos.get(
        youtubeVideoLink,
      );
      setState(() {
        _videoFound = true;
        videoMeta["title"] = videoMetaData.title;
        videoMeta["author"] = videoMetaData.author;
        videoMeta["date"] = videoMetaData.uploadDate.toString().split(' ')[0];
        videoMeta["description"] = videoMetaData.description;
        videoMeta["views"] = videoMetaData.engagement.likeCount.toString();
        videoMeta["thumbnail"] =
            "https://img.youtube.com/vi/${videoMetaData.id}/hqdefault.jpg";
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains("Invalid argument")) {
          error = "L'URL entré n'est pas valide veuillez réesayer";
        } else {
          error = e.toString();
        }
        ;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          showCloseIcon: true,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(15)),
        ));
      }
      print(error);
      yt.close();
    }
  }

  //fonction pour enregistrer la video
  Future<void> DownloadVideo(String videoLink) async {
    try {
      final yt = YoutubeExplode();
      var manifest = await yt.videos.streamsClient.getManifest(videoLink);
      var streamInfo = manifest.muxed.withHighestBitrate();

      // Pour l'exemple, on sauvegarde dans un fichier temporaire
      var file = File('Myvideo.mp4');
      var fileStream = file.openWrite();

      var stream = yt.videos.streamsClient.get(streamInfo);
      int totalBytes = streamInfo.size.totalBytes;
      int downloadedBytes = 0;

      // La boucle magique
      await for (var data in stream) {
        downloadedBytes += data.length;

        // On met à jour l'interface utilisateur !
        setState(() {
          _progress =
              downloadedBytes / totalBytes; // Donne un chiffre entre 0.0 et 1.0
          print(_progress);
        });

        fileStream.add(data);
      }

      await fileStream.close();
      yt.close();

      setState(() {
        _isDownloading = false;
        print("téléchargement terminé");
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  bool _isVisible = false;
  //function area
  //function si la vidéo est trouvé
  Widget showVideoData() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(15),
          child: Row(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              //video thumbnail
              children: [
                Expanded(
                    flex: 1,
                    child: Container(
                      height: 300,
                      width: 250,
                      //thumbnail image container
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: videoMeta["thumbnail"]!.isEmpty
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                              ),
                            )
                          : Image.network(
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                } else {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                }
                              },
                              videoMeta["thumbnail"]!,
                              fit: BoxFit.cover,
                            ),
                    )),
                Expanded(
                    flex: 1,
                    child: Container(
                      //video description
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            videoMeta['title'] ?? "",
                            maxLines: 3,
                            style: TextStyle(fontSize: 24),
                          ),
                          Text(
                            maxLines: 4,
                            videoMeta["description"] ?? "",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                          Text(
                            videoMeta["date"] ?? "",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          )
                        ],
                      ),
                    ))
              ]),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            //option button
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            spacing: 25,
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isVisible = false;
                    });
                    DownloadVideo(_searchController.text);
                  },
                  style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(15)),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(18)),
                  icon: Icon(
                    Icons.download,
                    size: 25,
                  ),
                  label: Text("Télécharger"),
                ),
              ),
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isVisible = false;
                    });
                  },
                  style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(15)),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(18)),
                  icon: Icon(
                    Icons.close,
                    size: 25,
                  ),
                  label: Text("Annuler"),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget downloadPopup() {
    return Stack(
      children: [
        Positioned.fill(
            child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            color: const Color.fromARGB(3, 0, 0, 0),
          ),
        )),
        Padding(
          padding: const EdgeInsets.all(50),
          child: Container(
              height: 400,
              //download popup
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(35)),
              child: _videoFound
                  ? showVideoData()
                  : Center(
                      //chargement des informations
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          Text("Récupération des informations ...")
                        ],
                      ),
                    ) //1
              ),
        )
      ],
    );
  }

  //handle submit
  final TextEditingController _searchController = TextEditingController();
  void handleSubmit(String link) {
    setState(() {
      error = "";
      _isVisible = true;
      videoMeta = {
        "title": "",
        "author": "",
        "date": "",
        "description": "",
        "views": "",
        "thumbnail": "",
      };
    });
    yd(link);
  }

  // Méthode pour construire la vue "Accueil"
  Widget _buildHome() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.asset(
            'assets/images/patern.jpg',
            width: double.maxFinite,
            colorBlendMode: BlendMode.darken,
            color: const Color.fromARGB(178, 0, 0, 0),
            fit: BoxFit.fill,
          ),
          Container(
            //foreground
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                spacing: 12,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Row(
                        //logo de mon application
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25)),
                            child: Image.asset(
                              "assets/images/ytd_img.png",
                              fit: BoxFit.cover,
                              height: 70,
                              width: 100,
                            ),
                          ),
                          Text(
                            "YVD",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 55,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        "Télécharcher aisément vos vidéo youtube",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      )
                    ],
                  ),
                  TextField(
                    controller: _searchController,
                    onSubmitted: handleSubmit,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        hintText: "Coller votre lien ici",
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: IconButton(
                          onPressed: () {
                            if (_searchController.text.isNotEmpty) {
                              handleSubmit(_searchController.text);
                            }
                          },
                          icon: Icon(Icons.forward),
                          padding: EdgeInsets.zero,
                        ),
                        border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(25)),
                        filled: true,
                        fillColor: Colors.white),
                  )
                ],
              ),
            ),
          ),
          if (_isVisible && error.isEmpty) downloadPopup()
        ],
      ),
    );
  }

  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
            padding: EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 8),
            width: 70,
            height: 70,
            child: Image.asset(
              "assets/images/ytd_img.png",
              fit: BoxFit.cover,
            ),
          ),
          title: Text("YOUTUBE VIDEO DOWNLOADER"),
        ),
        body: Container(
          color: Colors.grey[100],
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  padding: EdgeInsets.all(8),
                  //le corps de mon application
                  decoration: BoxDecoration(
                      // border: Border.all(color: Colors.red),
                      ),
                  child: selectedIndex == 0
                      ? _buildHome()
                      : selectedIndex == 1
                          ? const Dowloading()
                          : const Center(child: Text("Terminé")),
                ),
              )
            ],
          ),
        ));
  }
}
