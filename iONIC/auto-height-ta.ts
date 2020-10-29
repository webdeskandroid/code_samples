import { ElementRef, HostListener, Directive, OnInit } from '@angular/core';
import { Input } from '@angular/core';
import { FormGroup } from '@angular/forms';
/**
 * Directive use to automatic increase height of TextArea
 */
@Directive({
    selector: '[auto-height-ta]' // Attribute selector
})
export class AutoHeightTaDirective implements OnInit {

    addMargin: number = 0;
    @Input() myControl: FormGroup;
    @Input() controlName: string;
    @Input() addMarginTA: number;
    @Input() minHeightTA: number;
    currentHeight: any;

    constructor(public element: ElementRef) {
        this.addMargin = 0;
    }

    @HostListener('input', ['$event'])
    onInput($event): void {
        if (this.element.nativeElement.value == '') {
            console.log('auto-height-ta: we have nothing to change');
        } else {
            this.adjust();
        }
    }

    ngOnInit(): void {
        setTimeout(() => {
            if (this.addMarginTA) {
                this.addMargin = this.addMarginTA;
            }
            if (this.element) {
                try {
                    this.currentHeight = this.element.nativeElement.getElementsByTagName('textarea')[0].offsetHeight;
                    if (this.minHeightTA) {
                        this.currentHeight = this.minHeightTA;
                    }
                    this.adjust();
                } catch (e) {
                    console.error('auto-height-ta:error occurred', e);
                }
            } else {
                console.log('auto-height-ta:we have no element found');

            }
            if (this.myControl) {
                this.myControl.controls[this.controlName].valueChanges.subscribe((value) => {
                    this.adjust();
                });
            } else {
                console.error('auto-height-ta:my control not found');
            }
        }, 100);
    }
    adjust(): void {
        let textArea = this.element.nativeElement.getElementsByTagName('textarea')[0];
        textArea.style.minHeight = '0';
        textArea.style.height = '0';
        var scroll_height = textArea.scrollHeight;
        if (scroll_height < this.currentHeight) {
            scroll_height = this.currentHeight
        }// apply new style
        this.element.nativeElement.style.height = (scroll_height + this.addMargin) + "px";
        textArea.style.minHeight = scroll_height + "px";
        textArea.style.height = scroll_height + "px";
    }

}