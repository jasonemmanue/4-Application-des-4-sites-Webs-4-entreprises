import 'package:chic_residence_gestionnaire/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la tâche lit les champs réels de CleaningTaskOut', () {
    final t = CleaningTask.fromJson({
      'id': 't',
      'status': 'pending',
      'assigned_agent_id': 'a',
      'assigned_agent': {'full_name': 'Awa'},
      'rejection_reason': 'Vitres sales',
      'residence': {
        'id': 'r',
        'title': 'Studio',
        'city': 'Abidjan',
        'residence_type': 'studio',
      },
      'photos': [
        {'id': 'p', 'url': '/uploads/x.jpg', 'label': 'after'},
      ],
    });
    expect(t.agentName, 'Awa');
    expect(t.residenceTitle, 'Studio');
    expect(t.wasRejected, isTrue);
    expect(t.hasPhoto('after'), isTrue);
    expect(TaskStatusX.parse('validated'), TaskStatus.validated);
  });
}
