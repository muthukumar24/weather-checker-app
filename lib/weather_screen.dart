import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/additional_information.dart';
import 'package:weather_app/hourly_forcast_card.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> weather;

  String defaultCity = 'Chennai';
  String inputCityName = '';

  final TextEditingController textEditingController = TextEditingController();

  Future<Map<String, dynamic>> getCurrentWeather(String inputCityName) async {
    try {
      String cityName = inputCityName == "" ? defaultCity : inputCityName;
      String apiKey = dotenv.env['API_KEY'] ?? '';

      final result = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$apiKey'));

      final data = jsonDecode(result.body);

      if (int.parse(data['cod']) != 200) {
        throw 'An unexpected error occurred';
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    weather = getCurrentWeather(defaultCity);
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderSide: BorderSide(
        width: 2.0,
        style: BorderStyle.solid,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Weather Check",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  final city =
                      inputCityName.isEmpty ? defaultCity : inputCityName;
                  weather = getCurrentWeather(city);
                });
              },
              icon: Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: const CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;

          final currentWeatherData = data['list'][0];

          final currentTemperature = currentWeatherData['main']['temp'];

          final fahrenheitTemperature =
              (currentTemperature - 273.15) * 9 / 5 + 32;

          final currentSky = currentWeatherData['weather'][0]['main'];

          final currentPressure = currentWeatherData['main']['pressure'];

          final currentWindSpeed = currentWeatherData['wind']['speed'];

          final currentHumidity = currentWeatherData['main']['humidity'];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // City Input Box
                Container(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    controller: textEditingController,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter a City Name...",
                      hintStyle: TextStyle(
                        color: Colors.black,
                      ),
                      prefixIcon: Icon(Icons.search),
                      prefixIconColor: Colors.black,
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: border,
                      enabledBorder: border,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                // Check Button
                Container(
                  padding: EdgeInsets.all(0),
                  child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: Size(80, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(5),
                          ),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          inputCityName = textEditingController.text;
                          weather = getCurrentWeather(inputCityName);
                        });
                      },
                      child: Text("Check")),
                ),
                const SizedBox(
                  height: 20,
                ),
                // Main Card
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  '${inputCityName.isEmpty ? defaultCity : inputCityName} - ${fahrenheitTemperature.toStringAsFixed(2)}°',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Icon(
                                  currentSky == 'Clouds' || currentSky == 'Rain'
                                      ? Icons.cloud
                                      : Icons.sunny,
                                  size: 64,
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Text(
                                  '$currentSky',
                                  style: TextStyle(fontSize: 20),
                                )
                              ],
                            ),
                          )),
                    ),
                  ),
                ),
                // SizedBox adds gap between maincard and forecast card
                const SizedBox(
                  height: 20,
                ),
                // Weather Forecast Text and Cards
                const Text(
                  'Hourly Forecast',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                // Weather Forecast Cards
                // List View Builder
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final time = DateTime.parse(data['list'][index + 1]['dt_txt']);
                        final hourlyFahrenheitTemperature = ((data['list'][index + 1]['main']['temp'] -273.15) * 9 / 5 + 32).toStringAsFixed(2);
                        
                        return HourlyForecastCard(
                          time: DateFormat.jm().format(time),
                          icon: data['list'][index + 1]['weather'][0]['main'] == 'Clouds' 
                                ||
                                data['list'][index + 1]['weather'][0]['main'] == 'Rain'
                              ? Icons.cloud
                              : Icons.sunny,
                          temperature: hourlyFahrenheitTemperature,
                        );
                      }),
                ),

                const SizedBox(
                  height: 20,
                ),
                // Additional Info Text
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                // Additional Info Text Content
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AdditionalInformations(
                      icon: Icons.water_drop,
                      label: 'Humidity',
                      value: currentHumidity.toString(),
                    ),
                    AdditionalInformations(
                      icon: Icons.air,
                      label: 'Wind Speed',
                      value: currentWindSpeed.toString(),
                    ),
                    AdditionalInformations(
                      icon: Icons.timer,
                      label: 'Pressure',
                      value: currentPressure.toString(),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
