import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  final List<Map<String, dynamic>> pages = const [
    {'icon': Icons.document_scanner,'title':'Scan Smarter','description':'Capture documents with AI-powered OCR while preserving layout and formatting.'},
    {'icon': Icons.auto_awesome,'title':'AI Document Intelligence','description':'Generate summaries, notes, flashcards and translations instantly.'},
    {'icon': Icons.workspace_premium,'title':'Document Intelligence','description':'Perfect formatting reconstruction, regional language mastery and enterprise-ready APIs.'},
  ];

  void _next() {
    if (_current < pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: ()=>Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
              child: const Text('Skip'),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (i)=>setState(()=>_current=i),
              itemBuilder: (_,i)=>OnboardingPage(
                icon: pages[i]['icon'],
                title: pages[i]['title'],
                description: pages[i]['description'],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pages.length,(i)=>AnimatedContainer(
              duration: const Duration(milliseconds:250),
              margin: const EdgeInsets.all(4),
              width: _current==i?24:8,
              height:8,
              decoration: BoxDecoration(
                color:_current==i?Theme.of(context).colorScheme.primary:Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child:SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:_next,
                child: Text(_current==pages.length-1?'Get Started':'Next'),
              ),
            ),
          )
        ]),
      ),
    );
  }
}