import 'models.dart';

const sampleQuestions = [
  Question(
    id: 1,
    title: 'Психология ғылымының негізгі пәні не болып табылады?',
    options: [
      'Адам ағзасының физиологиялық қызметі',
      'Адамның жаны туралы ілім',
      'Адамзаттың өткен тарихы',
      'Психика және оның пайда болу, даму және жұмыс істеу заңдылықтары',
      'Қоғамдық құбылыстар мен процестер',
    ],
    choiceIds: const [null, null, null, null, null],
    correctOption: 3,
  ),
  Question(
    id: 2,
    title: 'Психология ғылымының әдістеріне не жатады?',
    options: [
      'Табиғи және лабораториялық эксперимент',
      'Бақылау және өзін-өзі бақылау',
      'Әңгімелесу және анкеталау',
      'Құжаттарды талдау',
      'Барлық жауаптар дұрыс',
    ],
    choiceIds: const [null, null, null, null, null],
    correctOption: 4,
  ),
  Question(
    id: 3,
    title: 'Тұлғаның темперамент типтері қаншаға бөлінеді?',
    options: [
      '3 тип',
      '4 тип',
      '5 тип',
      '6 тип',
      '7 тип',
    ],
    choiceIds: const [null, null, null, null, null],
    correctOption: 1,
  ),
  Question(
    id: 4,
    title: 'Гештальт психологиясының негізгі қағидалары қандай?',
    options: [
      'Сана құрылымын зерттеу',
      'Түйсінулерді элементтерге бөлу',
      'Перцептивтік тұтастық және ұйымдасу заңдылықтары',
      'Психоанализ теориясы',
      'Әлеуметтік факторларды талдау',
    ],
    choiceIds: const [null, null, null, null, null],
    correctOption: 2,
  ),
];

const sampleTests = [
  TestOption(
    id: '1',
    title: 'Психология',
    teacher: 'Бекболат Сабырбай',
    durationMinutes: 60,
    questionCount: 40,
    questions: sampleQuestions,
  ),
  TestOption(
    id: '2',
    title: 'История Казахстана',
    teacher: 'Айгерим Жаксыбек',
    durationMinutes: 45,
    questionCount: 30,
    questions: sampleQuestions,
  ),
];
