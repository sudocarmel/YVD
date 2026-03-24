import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class YoutubeDowloader extends StatefulWidget {
  const YoutubeDowloader({super.key});
  @override
  State<YoutubeDowloader> createState() => _YoutubeDowloaderState();
}

class _YoutubeDowloaderState extends State<YoutubeDowloader> {
  //sharedPreference
  Future<void> setIsFirstLunch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLunch', value);
  }

  //Read the preferences
  Future<bool> getIsFirstLunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isFirstLunch") ?? true;
  }

  //
  Future<void> initVideoDownload(String videoLink) async {
    try {
      final yt = YoutubeExplode();
      var manifest = await yt.videos.streamsClient.getManifest(videoLink);
      var streamInfo =
          manifest.muxed.withHighestBitrate(); //choix de la qualité

      if (videoDestinationPath.isEmpty) {
        await selectPath();
      }

      var file = File('$videoDestinationPath/${videoMeta["title"]}.mp4');
      var fileStream = file.openWrite();

      var stream = yt.videos.streamsClient.get(streamInfo);
      int totalBytes = streamInfo.size.totalBytes;
      int downloadedBytes = 0;

      // La boucle magique
      await for (var data in stream) {
        if (!_isDownloading) {
          await fileStream.close();
          yt.close();
          if (await file.exists()) {
            await file.delete();
          }
          return;
        }
        downloadedBytes += data.length;

        // On met à jour l'interface utilisateur !
        setState(() {
          _progress =
              downloadedBytes / totalBytes; // Donne un chiffre entre 0.0 et 1.0
        });

        fileStream.add(data);
      }

      await fileStream.close();
      yt.close();

      setState(() {
        _isDownloading = false;
        _textStatus = "téléchargement terminé";
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_textStatus),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(25),
          showCloseIcon: true,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(15)),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(25),
        content: Text(_textStatus),
        backgroundColor: const Color.fromARGB(164, 76, 175, 79),
        showCloseIcon: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(15)),
      ));
    }
  }

  //etat de la recherche sur youtube
  double _progress = 0.0;
  bool _isDownloading = false;
  bool isVideoDataWidgetvisible =
      false; //controle de l'affichage des infos sur la video
  bool _videoFound = false;
  String error = "";
  String videoDestinationPath = "";
  bool isFolderSelectionWidgetVisible = false;
  bool isFirstLunching = true;
  int _currentIndex = 0;
  int closeIconColor = 0xFF000000;
  Map<String, String> videoMeta = {
    "title": "",
    "author": "",
    "date": "",
    "description": "",
    "views": "",
    "thumbnail": "",
  };
  String _textStatus = "";
  bool showTutorial = false;
  //variable gardant l'état des boutons activé ou désactivé
  bool isprevButtonActive = false;
  bool isNextButtonActive = true;
  Future yd(String youtubeVideoLink) async {
    final yt = YoutubeExplode();
    setState(() {
      _progress = 0.0;
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
        } else if (e.toString().contains("name resolution")) {
          error = "Veuillez vérifier votre connection internet et réesayer";
        } else {
          error = e.toString();
        }
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(25),
          content: Text(error),
          backgroundColor: const Color.fromARGB(148, 244, 67, 54),
          showCloseIcon: true,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(8)),
        ));
      }
      yt.close();
    }
  }

  //fonction pour choisir l'emplacement de la video
  Future<void> selectPath() async {
    String? selectedDirectoryPath =
        await FilePicker.platform.getDirectoryPath();
    if (selectedDirectoryPath != null) {
      // Sauvegarder le chemin dans les préférences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('savedPath', selectedDirectoryPath);
      setState(() {
        videoDestinationPath = selectedDirectoryPath;
      });
    }
  }

  //fonction pour les différent widget du onBoarding
  Widget? onboardingWidget(int index) {
    switch (index) {
      case 0:
        return Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Column(
                  children: [
                    const Text(
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24),
                        "Bienvenu sur Youtube Video Downloader "),
                    const Text(
                      "L'outils pour télécharger n'importe quel vidéo depuis Youtube ",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Text(
                  style: TextStyle(fontSize: 14),
                  'Pour commencer, choisissez un emplacement pour sauvegarder vos vidéo'),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () async {
                      await selectPath();
                      if (videoDestinationPath.isNotEmpty) {
                        setState(() {
                          _currentIndex++;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Text("Choisir un emplacement")),
              ),
            ],
          ),
        );
      case 1:
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                  "Les Vidéos téléchargé seront enregistré dans le repertoire "),
              Row(
                spacing: 5,
                children: [
                  Icon(Icons.folder),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                          style: TextStyle(color: Colors.grey[600]),
                          videoDestinationPath.isEmpty
                              ? "Aucune destination choisie"
                              : videoDestinationPath),
                    ),
                  ),
                ],
              ),
              Text(
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                  "Pour les retrouver ouvrez votre gestionnaire de fichier et rendez-vous a cet emplacement")
            ],
          ),
        );
      case 2:
        return Container(
          width: 400,
          height: 220,
          margin:
              EdgeInsetsGeometry.only(top: 0, left: 15, right: 15, bottom: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text(
                "Tout est pret!",
                style: TextStyle(fontSize: 36),
              ),
              Transform.translate(
                offset: const Offset(0, 5),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        showTutorial = false;
                        setState(() {
                          _currentIndex = 0;
                          setIsFirstLunch(false);
                          isFirstLunching = false;
                          moveForOrBackward(false);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: Text("Commencer")),
                ),
              ),
              Text("Développé par CHABI Carmel & AMOUSSOU Ricardo"),
              TextButton.icon(
                onPressed: () async {
                  try {
                    await launchUrl(
                        Uri.parse("mailto:chabiaguecarmel@gmail.com"));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(25),
                          content: Text('Impossible d\'envoyer un mail : $e')),
                    );
                  }
                },
                icon: Image.asset("assets/images/gmail.png"),
                label: Text("Envoyer un email"),
              )
            ],
          ),
        );
      default:
        return null;
    }
  }

  //fonction pour les bouton suivant et précédent du onBoarding

  void moveForOrBackward(bool foreWard) {
    setState(() {
      if (foreWard) {
        if (_currentIndex < 2) _currentIndex++;
      } else {
        if (_currentIndex > 0) _currentIndex--;
      }
      isprevButtonActive = _currentIndex > 0;
      isNextButtonActive = _currentIndex < 2;
    });
  }

  //fonction pour enregistrer la video

  //widget a afficher au démarrage du téléchargement
  Widget downloadingVideoWidget(double progress) {
    return Container(
      //downloading widget
      width: 600,
      height: 150,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(23)),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  child: Row(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
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
                          flex: 2,
                          child: Text(
                            videoMeta["title"] ?? "No title found",
                            maxLines: 3,
                            style: TextStyle(fontSize: 22),
                          ))
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        borderRadius: BorderRadius.circular(15),
                        minHeight: 5,
                        color: Colors.red,
                        value: progress,
                      ),
                    ),
                    Expanded(
                        flex: 0,
                        child: Text(
                            "${(progress * 100).toString().split('.')[0]}﹪")),
                  ],
                ),
              )
            ],
          ),
          Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _isDownloading = false;
                    _textStatus = "Téléchargement annulé";
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(25),
                      showCloseIcon: true,
                      content: Text(_textStatus),
                      backgroundColor: const Color.fromARGB(129, 244, 67, 54)));
                },
                icon: Icon(
                  Icons.delete_forever,
                ),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
              ))
        ],
      ),
    );
  }

  bool _isDownloadingWidgetVisible = false;
  //function area
  //Widget pour acceullir l'utilisateur et lui faire choisir un repertoire pour les téléchargement
  Widget welcomeUser() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color.fromARGB(40, 0, 0, 0)),
        child: Container(
          width: 500,
          height: 450,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(25)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Transform.translate(
                offset: Offset(220, 0),
                child: IconButton(
                    onPressed: videoDestinationPath.isEmpty
                        ? null
                        : () {
                            setState(() {
                              showTutorial = false;
                              _currentIndex = 0;
                            });
                          },
                    disabledColor: Colors.transparent,
                    icon: const Icon(Icons.close)),
              ),
              //logo d'acceuil
              Expanded(
                flex: 1,
                child: Row(
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
                          color: Colors.black,
                          fontSize: 55,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              //swipe
              onboardingWidget(_currentIndex)!,
              //swipeEnd
              Container(
                //position indicator
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: videoDestinationPath.isEmpty
                            ? null
                            : isprevButtonActive
                                ? () => moveForOrBackward(false)
                                : null,
                        disabledColor: Colors.transparent,
                        icon: Icon(Icons.arrow_back_ios)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          height: 5,
                          width: _currentIndex == index ? 22 : 5,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: _currentIndex == index
                                  ? Colors.red
                                  : Colors.grey),
                        );
                      }),
                    ),
                    IconButton(
                        onPressed: videoDestinationPath.isEmpty
                            ? null
                            : isNextButtonActive
                                ? () => moveForOrBackward(true)
                                : null,
                        disabledColor: Colors.transparent,
                        icon: Icon(Icons.arrow_forward_ios)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

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
                      padding: EdgeInsets.all(8),
                      //video description
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      _textStatus = "Téléchargement annulé";
                      isVideoDataWidgetvisible = false;
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
              ),
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isVideoDataWidgetvisible = false;
                      _isDownloading = true;
                    });
                    initVideoDownload(_searchController.text);
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
            ],
          ),
        )
      ],
    );
  }

  Widget showVideoDataWidget() {
    //montre les données a propos de la video trouvé
    return Stack(
      children: [
        Positioned.fill(
            child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            color: const Color.fromARGB(3, 0, 0, 0),
          ),
        )),
        Container(
            margin: EdgeInsets.symmetric(vertical: 120, horizontal: 170),
            alignment: Alignment.center,
            height: 400,
            width: 1000,
            //download popup
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(25)),
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
      ],
    );
  }

  //handle submit
  final TextEditingController _searchController = TextEditingController();
  void handleSubmit(String link) {
    setState(() {
      error = "";
      isVideoDataWidgetvisible = true;
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
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/green_line.jpeg',
              width: double.maxFinite,
              colorBlendMode: BlendMode.darken,
              color: const Color.fromARGB(178, 0, 0, 0),
              fit: BoxFit.cover,
            ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                        "Téléchargez aisément vos vidéos youtube",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(58.0),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: handleSubmit,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          hintText: "Coller le lien de la vidéo youtuber ici",
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: IconButton(
                            onPressed: () {
                              if (_searchController.text.isNotEmpty) {
                                handleSubmit(_searchController.text);
                              }
                            },
                            icon: Icon(
                              Icons.forward,
                            ),
                            padding: EdgeInsets.zero,
                            color: Colors.red,
                          ),
                          border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(25)),
                          filled: true,
                          fillColor: Colors.white),
                    ),
                  ),
                  if (_isDownloading) downloadingVideoWidget(_progress)
                ],
              ),
            ),
          ),

          //dropDown Widget
          if (isFolderSelectionWidgetVisible)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 2),
                width: 350,
                height: 150,
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Vos vidéo sont enregistré dans:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      spacing: 5,
                      children: [
                        Icon(Icons.folder),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                                style: TextStyle(color: Colors.grey[600]),
                                videoDestinationPath.isEmpty
                                    ? "Aucune destination choisie"
                                    : videoDestinationPath),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: () async {
                            selectPath();
                            final prefs = await SharedPreferences.getInstance();
                            setState(() {
                              prefs.setString(
                                  'savedPath', videoDestinationPath);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: Text(
                              overflow: TextOverflow.fade,
                              videoDestinationPath.isEmpty
                                  ? "Choisir un emplacement"
                                  : "Changer l'emplacement")),
                    ),
                  ],
                ),
              ),
            ),
          if (isVideoDataWidgetvisible && error.isEmpty) showVideoDataWidget(),
          if (isFirstLunching || showTutorial)
            Positioned.fill(child: welcomeUser()),
        ],
      ),
    );
  }

  // Vérification au démarrage
  void check() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // On charge l'état du onboarding (true par défaut)
      isFirstLunching = prefs.getBool("isFirstLunch") ?? true;
      // On charge le chemin sauvegardé ("" par défaut)
      videoDestinationPath = prefs.getString('savedPath') ?? "";
    });
  }

  int selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    check();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 60,
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
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    showTutorial = !showTutorial;
                  });
                },
                label: Text("Aide"),
                icon: Icon(Icons.help),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isFolderSelectionWidgetVisible =
                        !isFolderSelectionWidgetVisible;
                  });
                },
                label: Text(
                    isFolderSelectionWidgetVisible ? "Annuler" : "Destination"),
                icon: Icon(isFolderSelectionWidgetVisible
                    ? Icons.close
                    : Icons.folder),
              ),
            )
          ],
        ),
        body: _buildHome());
  }
}
