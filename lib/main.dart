import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const JudgesSelectionApp());
}

class JudgesSelectionApp extends StatelessWidget {
  const JudgesSelectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsApp Group Judges Selection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> members = [
    'Sohail Afzal',
    'Hashim Khan',
    'Muhammad Taufeeq',
    'Ali Arslan',
    'Muhammad Hamza',
    'Imtiaz Ahmad',
    'Kabir Ahmad',
    'Malik Zulfiqar Ali',
    'Muhammad Rasheed',
    'Muhammad Tahir Khan',
    'Rafae Munir',
    'Rana Mehmood Iqbal',
    'Rana Waqar Azeem',
    'Sajid Khalil',
    'Salar Ayub',
  ];

  String? currentVoter;
  String? presidingOfficer;
  final List<String> selectedJudges = [];
  final Map<String, int> votes = {};
  final Map<String, List<String>> allVotes = {};
  final List<String> votedMembers = [];
  bool isVerified = false;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _resetCodeController = TextEditingController();
  final TextEditingController _memberNameController = TextEditingController();
  final TextEditingController _judgesCountController = TextEditingController(
    text: '3',
  );
  bool isPresidingOfficerSet = false;
  bool showAdminControls = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    for (var member in members) {
      votes[member] = 0;
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPresidingOfficerSet = prefs.getBool('isPresidingOfficerSet') ?? false;
      presidingOfficer = prefs.getString('presidingOfficer');
      showAdminControls = prefs.getBool('showAdminControls') ?? false;
      votedMembers.addAll(prefs.getStringList('votedMembers') ?? []);
      final allVotesKeys = prefs.getStringList('allVotesKeys') ?? [];
      for (var key in allVotesKeys) {
        allVotes[key] = prefs.getStringList('allVotes_$key') ?? [];
      }
      members = prefs.getStringList('members') ?? members;

      // Rebuild votes count from allVotes
      for (var member in members) {
        votes[member] = 0;
      }
      for (var voter in allVotes.keys) {
        for (var judge in allVotes[voter]!) {
          votes[judge] = (votes[judge] ?? 0) + 1;
        }
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('votedMembers', votedMembers);
    await prefs.setStringList('allVotesKeys', allVotes.keys.toList());
    for (var key in allVotes.keys) {
      await prefs.setStringList('allVotes_$key', allVotes[key]!);
    }
    await prefs.setStringList('members', members);
    await prefs.setBool('isPresidingOfficerSet', isPresidingOfficerSet);
    await prefs.setString('presidingOfficer', presidingOfficer ?? '');
    await prefs.setBool('showAdminControls', showAdminControls);
  }

  void _verifyCode() {
    if (_codeController.text == '1122') {
      setState(() {
        isVerified = true;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification successful!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
    _codeController.clear();
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Security Code'),
            content: TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '4-digit code (****)',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(onPressed: _verifyCode, child: const Text('Verify')),
            ],
          ),
    );
  }

  void _resetVoting() {
    if (_resetCodeController.text == '1122') {
      setState(() {
        votedMembers.clear();
        allVotes.clear();
        selectedJudges.clear();
        currentVoter = null;
        isVerified = false;
        for (var member in members) {
          votes[member] = 0;
        }
      });
      _saveData();
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Voting has been reset!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid security code. Please try again.'),
        ),
      );
    }
    _resetCodeController.clear();
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Voting'),
            content: TextField(
              controller: _resetCodeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter security code (1122)',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(onPressed: _resetVoting, child: const Text('Reset')),
            ],
          ),
    );
  }

  void _submitVote() {
    if (currentVoter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your name first')),
      );
      return;
    }

    if (!isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify with security code first')),
      );
      _showVerificationDialog();
      return;
    }

    int judgesCount = int.tryParse(_judgesCountController.text) ?? 3;
    if (selectedJudges.length != judgesCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select exactly $judgesCount judges')),
      );
      return;
    }

    if (votedMembers.contains(currentVoter)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$currentVoter has already voted!')),
      );
      return;
    }

    allVotes[currentVoter!] = List.from(selectedJudges);
    votedMembers.add(currentVoter!);

    for (var judge in selectedJudges) {
      votes[judge] = votes[judge]! + 1;
    }

    setState(() {
      selectedJudges.clear();
      isVerified = false;
    });

    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$currentVoter has voted successfully!'),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.indigoAccent,
      ),
    );
  }

  String _getResultsText() {
    var sortedResults =
        votes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    int judgesCount = int.tryParse(_judgesCountController.text) ?? 3;
    String resultText =
        "📊 BARQAAB WhatsApp Group Judges Selection Results\n\n";
    resultText += "🏆 Top $judgesCount Judges:\n";

    for (int i = 0; i < judgesCount && i < sortedResults.length; i++) {
      resultText +=
          "${i + 1}. ${sortedResults[i].key} - ${sortedResults[i].value} votes\n";
    }

    resultText += "\nAll Votes:\n";
    for (var entry in sortedResults) {
      resultText += "${entry.key}: ${entry.value} votes\n";
    }

    resultText += "\nTotal Voters: ${votedMembers.length}/${members.length}\n";
    resultText += "Voted Members: ${votedMembers.join(', ')}";

    return resultText;
  }

  void _shareResults() {
    final resultsText = _getResultsText();
    Clipboard.setData(ClipboardData(text: resultsText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results copied to clipboard!')),
    );
  }

  void _showResults() {
    var sortedResults =
        votes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    int judgesCount = int.tryParse(_judgesCountController.text) ?? 3;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Voting Results'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (votedMembers.isEmpty)
                      const Text('No votes have been submitted yet.')
                    else ...[
                      Text(
                        'Top $judgesCount Judges:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      for (
                        int i = 0;
                        i < judgesCount && i < sortedResults.length;
                        i++
                      )
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${i + 1}. ${sortedResults[i].key}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${sortedResults[i].value} votes',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'All Votes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: sortedResults.length,
                          itemBuilder: (context, index) {
                            var entry = sortedResults[index];
                            return ListTile(
                              title: Text(
                                entry.key,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text('${entry.value} votes'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Total Voters: ${votedMembers.length}/${members.length}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              if (votedMembers.isNotEmpty)
                TextButton(
                  onPressed: _shareResults,
                  child: const Text('Share'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showVotingStatus() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Voting Status'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total members: ${members.length}'),
                    Text('Voted members: ${votedMembers.length}'),
                    Text(
                      'Remaining members: ${members.length - votedMembers.length}',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Voted members:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    votedMembers.isEmpty
                        ? const Text('No votes yet')
                        : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: votedMembers.length,
                            itemBuilder:
                                (context, index) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Text(votedMembers[index]),
                                ),
                          ),
                        ),
                    const SizedBox(height: 16),
                    if (showAdminControls)
                      ElevatedButton(
                        onPressed: _showResetDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Reset Voting'),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _addMember() {
    String newMember = _memberNameController.text.trim();
    if (newMember.isNotEmpty && !members.contains(newMember)) {
      setState(() {
        members.add(newMember);
        votes[newMember] = 0;
        _memberNameController.clear();
      });
      _saveData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$newMember added successfully!')));
    } else if (members.contains(newMember)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Member already exists!')));
    }
  }

  void _removeMember(String member) {
    if (member == presidingOfficer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove the presiding officer!')),
      );
      return;
    }

    setState(() {
      members.remove(member);
      votes.remove(member);
      if (allVotes.containsKey(member)) {
        allVotes.remove(member);
      }
      votedMembers.remove(member);
      // Remove votes for this member from other voters
      for (var voter in allVotes.keys) {
        allVotes[voter]!.remove(member);
      }
      // Recalculate votes
      for (var m in members) {
        votes[m] = 0;
      }
      for (var voter in allVotes.keys) {
        for (var judge in allVotes[voter]!) {
          votes[judge] = (votes[judge] ?? 0) + 1;
        }
      }
    });
    _saveData();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$member removed successfully!')));
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Member'),
            content: TextField(
              controller: _memberNameController,
              decoration: const InputDecoration(
                labelText: 'Member Name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _addMember();
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showSetPresidingOfficerDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Set Presiding Officer'),
            content: SizedBox(
              width: double.maxFinite,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Presiding Officer',
                  border: OutlineInputBorder(),
                ),
                value: presidingOfficer,
                items:
                    members.map((member) {
                      return DropdownMenuItem(
                        value: member,
                        child: Text(member),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    presidingOfficer = value;
                  });
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (presidingOfficer != null) {
                    setState(() {
                      isPresidingOfficerSet = true;
                      showAdminControls = currentVoter == presidingOfficer;
                    });
                    _saveData();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$presidingOfficer set as Presiding Officer!',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Set'),
              ),
            ],
          ),
    );
  }

  void _showAdminSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Admin Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _judgesCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of Judges to Select',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Members List:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: members.length,
                      itemBuilder:
                          (context, index) => ListTile(
                            title: Text(members[index]),
                            trailing:
                                members[index] != presidingOfficer
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _removeMember(members[index]),
                                    )
                                    : const Tooltip(
                                      message: 'Presiding Officer',
                                      child: Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.green,
                                      ),
                                    ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: _showAddMemberDialog,
                child: const Text('Add Member'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BARQAAB Whatsapp Group Judges Selection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: _showResults,
            tooltip: 'View Results',
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showVotingStatus,
            tooltip: 'Voting Status',
          ),
          if (showAdminControls)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showAdminSettingsDialog,
              tooltip: 'Admin Settings',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isPresidingOfficerSet) ...[
              ElevatedButton(
                onPressed: _showSetPresidingOfficerDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Set Presiding Officer',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select your name',
                border: OutlineInputBorder(),
              ),
              value: currentVoter,
              items:
                  members.map((member) {
                    return DropdownMenuItem(
                      value: member,
                      child: Text(member),
                      enabled: !votedMembers.contains(member),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  currentVoter = value;
                  selectedJudges.clear();
                  isVerified = false;
                  showAdminControls = value == presidingOfficer;
                });
                if (value != null && !votedMembers.contains(value)) {
                  _showVerificationDialog();
                }
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Select ${_judgesCountController.text} judges (excluding yourself):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (currentVoter != null) ...[
              const SizedBox(height: 10),
              Text(
                'Voting as: $currentVoter',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              if (currentVoter == presidingOfficer)
                const Text(
                  'Presiding Officer',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (!isVerified) ...[
                const SizedBox(height: 10),
                Text(
                  'Verification required',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 10),
            Expanded(
              child:
                  currentVoter == null
                      ? const Center(
                        child: Text(
                          'Please select your name first',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          if (member == currentVoter)
                            return const SizedBox.shrink();

                          final isAlreadyVoted = votedMembers.contains(
                            currentVoter,
                          );

                          return CheckboxListTile(
                            title: Text(member),
                            value: selectedJudges.contains(member),
                            onChanged:
                                (isAlreadyVoted || !isVerified)
                                    ? null
                                    : (selected) {
                                      setState(() {
                                        int judgesCount =
                                            int.tryParse(
                                              _judgesCountController.text,
                                            ) ??
                                            3;
                                        if (selected == true) {
                                          if (selectedJudges.length <
                                              judgesCount) {
                                            selectedJudges.add(member);
                                          }
                                        } else {
                                          selectedJudges.remove(member);
                                        }
                                      });
                                    },
                            secondary:
                                selectedJudges.contains(member)
                                    ? CircleAvatar(
                                      backgroundColor: Colors.green,
                                      child: Text(
                                        '${selectedJudges.indexOf(member) + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                    : null,
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  (votedMembers.contains(currentVoter) || !isVerified)
                      ? null
                      : _submitVote,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: Text(
                votedMembers.contains(currentVoter)
                    ? 'Already Voted'
                    : isVerified
                    ? 'Submit Vote'
                    : 'Verify to Submit',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
