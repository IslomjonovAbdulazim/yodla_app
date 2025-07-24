import 'package:country_flags/country_flags.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:svg_flutter/svg_flutter.dart';
import 'package:yodla_app/widgets/button.dart';
import 'package:yodla_app/widgets/common_button_type.dart';

import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  LoginView({super.key});

  final mask = MaskTextInputFormatter(
    mask: "(##) ###-##-##",
    filter: {"#": RegExp(r"[0-9]")},
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Help text
              Align(
                alignment: Alignment.centerRight,
                child: Button.tertiary(
                  padding: EdgeInsets.zero,
                  child: Text(
                    'Yordam kerakmi?',
                    style: GoogleFonts.armata(
                      fontSize: 16,
                      color: Color(0xFF7AB2D3),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10),
              // Title
              Text(
                'Kirish',
                style: GoogleFonts.armata(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              // Subtitle
              SizedBox(height: 5),
              Text(
                'Telefon raqamingizni kiriting',
                style: GoogleFonts.armata(
                  fontSize: 16,
                  color: Color(0xFF7AB2D3),
                ),
              ),

              const SizedBox(height: 30),

              // Uzbekistan flag

              // Phone input
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Container(
                      height: 80,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Color(0xffFAFAFA),
                      ),
                      child: Row(
                        children: [
                          CountryFlag.fromCountryCode(
                            "uz",
                            shape: Circle(),
                            height: 30,
                            width: 30,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '+998',
                            style: GoogleFonts.armata(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xffFAFAFA),
                          hintText: 'Telefon raqami',
                          hintStyle: GoogleFonts.armata(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.armata(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [mask],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Button(
                  type: CommonButtonType.primary,
                  borderColor: Color(0xffACCEE3),
                  buttonColor: Color(0xff7AB2D3),
                  onPressed: () {
                    // Just for show - doesn't work
                  },
                  child: Text(
                    'Davom etish',
                    style: GoogleFonts.armata(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Or divider
              Row(
                children: [
                  Expanded(
                    child: DottedLine(dashColor: Color(0xffACCEE3)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'yoki',
                      style: GoogleFonts.armata(
                        fontSize: 14,
                        color: Color(0xFF7AB2D3),
                      ),
                    ),
                  ),
                  Expanded(
                    child: DottedLine(dashColor: Color(0xffACCEE3)),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Social buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Obx(() {
                      return Button(
                        type: CommonButtonType.primary,
                        borderColor: Color(0xffACCEE3),
                        buttonColor: Colors.white,
                        onPressed: controller.isLoading
                            ? null
                            : () => controller.signInWithApple(),
                        child: SvgPicture.asset("assets/apple.svg"),
                      );
                    }),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Button(
                      type: CommonButtonType.primary,
                      borderColor: Color(0xffACCEE3),
                      buttonColor: Colors.white,
                      onPressed: () {},
                      child: SvgPicture.asset("assets/google.svg"),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Button(
                      type: CommonButtonType.primary,
                      borderColor: Color(0xffACCEE3),
                      buttonColor: Colors.white,
                      onPressed: () {},
                      child: Icon(Icons.telegram),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Terms and privacy
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.armata(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    children: [
                      TextSpan(text: 'By continuing you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: GoogleFonts.armata(
                          color: Color(0xFF7AB2D3),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: GoogleFonts.armata(
                          color: Color(0xFF7AB2D3),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
